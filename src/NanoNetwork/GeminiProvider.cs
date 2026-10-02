using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;

namespace NanoCorona.Network
{
    public sealed class GeminiProvider : IImageProvider
    {
        public string Name { get { return "Gemini"; } }

        private static readonly HttpClient Http = CreateHttpClient();

        private static HttpClient CreateHttpClient()
        {
            var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("NanoCorona/0.1");
            return client;
        }

        public async Task<ProviderResponse> GenerateAsync(
            ProviderRequest request,
            string apiKey,
            NanoNetworkOptions options,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(apiKey))
                return Failure("AUTH_MISSING", "Gemini API key is empty.", 0);

            var endpoint = string.Format(
                options.GeminiEndpoint,
                Uri.EscapeDataString(request.Model));

            var body = BuildRequestBody(request);
            var json = new JavaScriptSerializer().Serialize(body);

            for (var attempt = 0; attempt <= options.MaxRetries; attempt++)
            {
                cancellationToken.ThrowIfCancellationRequested();

                try
                {
                    using (var content = new StringContent(json, Encoding.UTF8, "application/json"))
                    using (var message = new HttpRequestMessage(HttpMethod.Post, endpoint))
                    {
                        message.Headers.TryAddWithoutValidation("x-goog-api-key", apiKey);
                        message.Content = content;

                        using (var response = await SendAsyncWithTimeout(message, options.Timeout, cancellationToken))
                        {
                            var raw = await response.Content.ReadAsStringAsync();

                            if ((int)response.StatusCode == 429 || IsTransient(response.StatusCode))
                            {
                                if (attempt < options.MaxRetries)
                                {
                                    await DelayForRetry(attempt, response, cancellationToken);
                                    continue;
                                }
                            }

                            if (!response.IsSuccessStatusCode)
                                return ParseError(response.StatusCode, raw);

                            return ParseSuccess(raw);
                        }
                    }
                }
                catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
                {
                    if (attempt < options.MaxRetries)
                    {
                        await DelayForRetry(attempt, null, cancellationToken);
                        continue;
                    }
                    return Failure("TIMEOUT", "Gemini request timed out.", 408);
                }
                catch (HttpRequestException ex)
                {
                    if (attempt < options.MaxRetries)
                    {
                        await DelayForRetry(attempt, null, cancellationToken);
                        continue;
                    }
                    return Failure("NETWORK_ERROR", ex.Message, 0);
                }
            }

            return Failure("RETRY_EXHAUSTED", "Gemini request failed after retries.", 0);
        }

        public Task<ProviderResponse> AnalyzeAsync(
            ProviderRequest request,
            string apiKey,
            NanoNetworkOptions options,
            CancellationToken cancellationToken)
        {
            return SendAnalysisAsync(request, apiKey, options, cancellationToken);
        }

        private async Task<ProviderResponse> SendAnalysisAsync(
            ProviderRequest request,
            string apiKey,
            NanoNetworkOptions options,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(apiKey))
                return Failure("AUTH_MISSING", "Gemini API key is empty.", 0);

            var endpoint = string.Format(options.GeminiEndpoint, Uri.EscapeDataString("gemini-3-pro-image"));
            var parts = new List<object> { new Dictionary<string, object> { { "text", request.Prompt } } };
            foreach (var image in request.Images)
                parts.Add(new Dictionary<string, object> { { "inline_data", new Dictionary<string, object> { { "mime_type", image.MimeType }, { "data", image.Base64Data } } } });

            var body = new Dictionary<string, object>
            {
                { "contents", new object[] { new Dictionary<string, object> { { "role", "user" }, { "parts", parts.ToArray() } } } },
                { "generationConfig", new Dictionary<string, object> { { "responseModalities", new[] { "TEXT" } } } }
            };
            var json = new JavaScriptSerializer().Serialize(body);

            using (var content = new StringContent(json, Encoding.UTF8, "application/json"))
            using (var message = new HttpRequestMessage(HttpMethod.Post, endpoint))
            {
                message.Headers.TryAddWithoutValidation("x-goog-api-key", apiKey);
                message.Content = content;
                using (var response = await SendAsyncWithTimeout(message, options.Timeout, cancellationToken))
                {
                    var raw = await response.Content.ReadAsStringAsync();
                    if (!response.IsSuccessStatusCode) return ParseError(response.StatusCode, raw);
                    var parsed = ParseTextSuccess(raw);
                    return parsed;
                }
            }
        }

        private static Dictionary<string, object> BuildRequestBody(ProviderRequest request)
        {
            var parts = new List<object>();
            parts.Add(new Dictionary<string, object> { { "text", request.Prompt } });

            foreach (var image in request.Images)
            {
                parts.Add(new Dictionary<string, object>
                {
                    { "inline_data", new Dictionary<string, object>
                        {
                            { "mime_type", image.MimeType },
                            { "data", image.Base64Data }
                        }
                    }
                });
            }

            return new Dictionary<string, object>
            {
                { "contents", new object[]
                    {
                        new Dictionary<string, object>
                        {
                            { "role", "user" },
                            { "parts", parts.ToArray() }
                        }
                    }
                },
                { "generationConfig", new Dictionary<string, object>
                    {
                        { "responseModalities", new[] { "IMAGE" } },
                        { "responseFormat", new Dictionary<string, object>
                            {
                                { "image", new Dictionary<string, object>
                                    {
                                        { "aspectRatio", string.IsNullOrWhiteSpace(request.AspectRatio) ? "16:9" : request.AspectRatio },
                                        { "imageSize", NormalizeResolution(request.Resolution) }
                                    }
                                }
                            }
                        }
                    }
                }
            };
        }

        private static string NormalizeResolution(string value)
        {
            if (string.Equals(value, "4K", StringComparison.OrdinalIgnoreCase)) return "4K";
            if (string.Equals(value, "2K", StringComparison.OrdinalIgnoreCase)) return "2K";
            return "1K";
        }

        private static bool IsTransient(HttpStatusCode status)
        {
            var code = (int)status;
            return code == 408 || code == 409 || code == 425 || code >= 500;
        }

        private static async Task DelayForRetry(
            int attempt,
            HttpResponseMessage response,
            CancellationToken cancellationToken)
        {
            var seconds = Math.Min(20, 2 * Math.Pow(2, attempt));

            if (response != null && response.Headers.RetryAfter != null)
            {
                var retry = response.Headers.RetryAfter.Delta;
                if (retry.HasValue)
                    seconds = Math.Min(60, Math.Max(1, retry.Value.TotalSeconds));
            }

            await Task.Delay(TimeSpan.FromSeconds(seconds), cancellationToken);
        }

        private static async Task<HttpResponseMessage> SendAsyncWithTimeout(
            HttpRequestMessage message,
            TimeSpan timeout,
            CancellationToken cancellationToken)
        {
            using (var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken))
            {
                timeoutCts.CancelAfter(timeout);
                return await Http.SendAsync(
                    message,
                    HttpCompletionOption.ResponseContentRead,
                    timeoutCts.Token);
            }
        }

        private static ProviderResponse ParseTextSuccess(string raw)
        {
            var root = new JavaScriptSerializer().DeserializeObject(raw) as Dictionary<string, object>;
            if (root == null) return Failure("INVALID_RESPONSE", "Gemini returned invalid JSON.", 200, raw);
            string text = null;
            var candidates = GetArray(root, "candidates");
            if (candidates != null)
                foreach (var candidateObj in candidates)
                {
                    var candidate = candidateObj as Dictionary<string, object>;
                    var content = candidate == null ? null : GetObject(candidate, "content");
                    var parts = content == null ? null : GetArray(content, "parts");
                    if (parts == null) continue;
                    foreach (var partObj in parts)
                    {
                        var part = partObj as Dictionary<string, object>;
                        var value = part == null ? null : GetString(part, "text");
                        if (!string.IsNullOrEmpty(value)) text = value;
                    }
                }
            if (string.IsNullOrWhiteSpace(text)) return Failure("NO_TEXT", "Gemini returned no QA text.", 200, raw);
            return new ProviderResponse { Success = true, Text = text, HttpStatus = 200, RawResponse = raw };
        }

        private static ProviderResponse ParseSuccess(string raw)
        {
            var root = new JavaScriptSerializer().DeserializeObject(raw) as Dictionary<string, object>;
            if (root == null)
                return Failure("INVALID_RESPONSE", "Gemini returned invalid JSON.", 200, raw);

            string text = null;
            byte[] image = null;
            string mime = null;

            var candidates = GetArray(root, "candidates");
            if (candidates != null)
            {
                foreach (var candidateObj in candidates)
                {
                    var candidate = candidateObj as Dictionary<string, object>;
                    var content = candidate == null ? null : GetObject(candidate, "content");
                    var parts = content == null ? null : GetArray(content, "parts");
                    if (parts == null) continue;

                    foreach (var partObj in parts)
                    {
                        var part = partObj as Dictionary<string, object>;
                        if (part == null) continue;

                        var textValue = GetString(part, "text");
                        if (!string.IsNullOrEmpty(textValue)) text = textValue;

                        var inline = GetObject(part, "inlineData");
                        if (inline == null) inline = GetObject(part, "inline_data");

                        if (inline != null)
                        {
                            var data = GetString(inline, "data");
                            if (!string.IsNullOrEmpty(data))
                            {
                                try
                                {
                                    image = Convert.FromBase64String(data);
                                    mime = GetString(inline, "mimeType") ?? GetString(inline, "mime_type");
                                }
                                catch (FormatException)
                                {
                                    return Failure("INVALID_IMAGE", "Gemini returned invalid base64 image data.", 200, raw);
                                }
                            }
                        }
                    }
                }
            }

            if (image == null || image.Length == 0)
                return Failure("NO_IMAGE", "Gemini returned no image.", 200, raw);

            return new ProviderResponse
            {
                Success = true,
                ImageBytes = image,
                ImageMimeType = mime ?? "image/png",
                Text = text,
                HttpStatus = 200,
                RawResponse = raw
            };
        }

        private static ProviderResponse ParseError(HttpStatusCode status, string raw)
        {
            var code = "HTTP_" + (int)status;
            var message = "Gemini HTTP error " + (int)status + ".";

            try
            {
                var root = new JavaScriptSerializer().DeserializeObject(raw) as Dictionary<string, object>;
                var error = root == null ? null : GetObject(root, "error");
                if (error != null)
                {
                    code = GetString(error, "status") ?? code;
                    message = GetString(error, "message") ?? message;
                }
            }
            catch { }

            return Failure(code, message, (int)status, raw);
        }

        private static ProviderResponse Failure(string code, string message, int status, string raw = null)
        {
            return new ProviderResponse
            {
                Success = false,
                ErrorCode = code,
                ErrorMessage = message,
                HttpStatus = status,
                RawResponse = raw
            };
        }

        private static Dictionary<string, object> GetObject(Dictionary<string, object> source, string key)
        {
            object value;
            return source.TryGetValue(key, out value) ? value as Dictionary<string, object> : null;
        }

        private static object[] GetArray(Dictionary<string, object> source, string key)
        {
            object value;
            return source.TryGetValue(key, out value) ? value as object[] : null;
        }

        private static string GetString(Dictionary<string, object> source, string key)
        {
            object value;
            if (!source.TryGetValue(key, out value) || value == null) return null;
            return value as string ?? Convert.ToString(value);
        }
    }
}