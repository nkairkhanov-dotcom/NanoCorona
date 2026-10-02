using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;

namespace NanoCorona.Network
{
    public sealed class NanoNetworkClient
    {
        private readonly IImageProvider _provider;
        private readonly NanoNetworkOptions _options;

        public NanoNetworkClient() : this(new GeminiProvider(), new NanoNetworkOptions()) { }

        public NanoNetworkClient(IImageProvider provider, NanoNetworkOptions options)
        {
            if (provider == null) throw new ArgumentNullException(nameof(provider));
            if (options == null) throw new ArgumentNullException(nameof(options));
            _provider = provider;
            _options = options;
        }

        public Task<GenerationResult> GenerateAsync(
            GenerationRequest request,
            string apiKey,
            CancellationToken cancellationToken)
        {
            return Task.Run(
                () => GenerateCoreAsync(request, apiKey, cancellationToken),
                cancellationToken);
        }

        private async Task<GenerationResult> GenerateCoreAsync(
            GenerationRequest request,
            string apiKey,
            CancellationToken cancellationToken)
        {
            var sw = Stopwatch.StartNew();

            try
            {
                ValidateRequest(request);

                var providerRequest = BuildProviderRequest(request);
                var response = await _provider.GenerateAsync(
                    providerRequest, apiKey, _options, cancellationToken);

                if (!response.Success)
                    return FailureResult(request, response, sw.ElapsedMilliseconds);

                var outputPath = ResolveOutputPath(request, response.ImageMimeType);
                var outputDirectory = Path.GetDirectoryName(outputPath);
                if (!string.IsNullOrEmpty(outputDirectory))
                    Directory.CreateDirectory(outputDirectory);

                File.WriteAllBytes(outputPath, response.ImageBytes);

                return new GenerationResult
                {
                    Success = true,
                    Provider = _provider.Name,
                    Model = request.Model,
                    ResultPath = outputPath,
                    RequestId = response.RequestId,
                    Text = response.Text,
                    HttpStatus = response.HttpStatus,
                    DurationMs = sw.ElapsedMilliseconds
                };
            }
            catch (OperationCanceledException)
            {
                return new GenerationResult
                {
                    Success = false,
                    Provider = _provider.Name,
                    Model = request == null ? null : request.Model,
                    ErrorCode = "CANCELED",
                    ErrorMessage = "Generation was canceled.",
                    DurationMs = sw.ElapsedMilliseconds
                };
            }
            catch (Exception ex)
            {
                return new GenerationResult
                {
                    Success = false,
                    Provider = _provider.Name,
                    Model = request == null ? null : request.Model,
                    ErrorCode = ex is NanoNetworkException
                        ? ((NanoNetworkException)ex).ErrorCode
                        : "CLIENT_ERROR",
                    ErrorMessage = ex.Message,
                    DurationMs = sw.ElapsedMilliseconds
                };
            }
        }

        public string BuildDiagnosticsJson(GenerationRequest request)
        {
            ValidateRequest(request);
            var providerRequest = BuildProviderRequest(request);
            var images = new List<object>();

            foreach (var image in providerRequest.Images)
            {
                images.Add(new Dictionary<string, object>
                {
                    { "role", image.Role },
                    { "mimeType", image.MimeType },
                    { "sourcePath", image.SourcePath },
                    { "bytes", new FileInfo(image.SourcePath).Length }
                });
            }

            return new JavaScriptSerializer().Serialize(new Dictionary<string, object>
            {
                { "provider", _provider.Name },
                { "model", providerRequest.Model },
                { "promptLength", providerRequest.Prompt.Length },
                { "strength", providerRequest.Strength },
                { "resolution", providerRequest.Resolution },
                { "images", images.ToArray() }
            });
        }

        private ProviderRequest BuildProviderRequest(GenerationRequest request)
        {
            var scene = File.ReadAllText(request.SceneJsonPath, Encoding.UTF8);
            var aspectRatio = ReadAspectRatio(scene);

            return new ProviderRequest
            {
                Provider = _provider.Name,
                Model = string.IsNullOrWhiteSpace(request.Model)
                    ? "gemini-3-pro-image"
                    : request.Model,
                Prompt = BuildPrompt(request, scene),
                Resolution = string.IsNullOrWhiteSpace(request.Resolution) ? "2K" : request.Resolution,
                AspectRatio = aspectRatio,
                Strength = ClampStrength(request.Strength),
                Images = new List<ProviderImagePart>
                {
                    ReadImage("beauty", request.BeautyPath),
                    ReadImage("depth", request.DepthPath),
                    ReadImage("normals", request.NormalsPath),
                    ReadImage("architecture-mask", request.ArchitectureMaskPath)
                }
            };
        }

        private static string ReadAspectRatio(string sceneJson)
        {
            try
            {
                var root = new JavaScriptSerializer().DeserializeObject(sceneJson) as Dictionary<string, object>;
                var scene = root == null ? null : GetObject(root, "scene");
                var render = scene == null ? null : GetObject(scene, "render");
                var width = GetDouble(render, "width");
                var height = GetDouble(render, "height");
                if (width > 0 && height > 0)
                {
                    var ratio = width / height;
                    var candidates = new[]
                    {
                        new { Name = "1:1", Value = 1.0 },
                        new { Name = "4:3", Value = 4.0 / 3.0 },
                        new { Name = "3:2", Value = 3.0 / 2.0 },
                        new { Name = "16:9", Value = 16.0 / 9.0 },
                        new { Name = "21:9", Value = 21.0 / 9.0 },
                        new { Name = "9:16", Value = 9.0 / 16.0 },
                        new { Name = "3:4", Value = 3.0 / 4.0 }
                    };

                    var nearest = candidates[0];
                    var distance = Math.Abs(ratio - nearest.Value);
                    foreach (var candidate in candidates)
                    {
                        var candidateDistance = Math.Abs(ratio - candidate.Value);
                        if (candidateDistance < distance)
                        {
                            nearest = candidate;
                            distance = candidateDistance;
                        }
                    }

                    return nearest.Name;
                }
            }
            catch { }

            return "16:9";
        }

        private static Dictionary<string, object> GetObject(Dictionary<string, object> source, string key)
        {
            if (source == null) return null;
            object value;
            return source.TryGetValue(key, out value) ? value as Dictionary<string, object> : null;
        }

        private static double GetDouble(Dictionary<string, object> source, string key)
        {
            if (source == null) return 0;
            object value;
            if (!source.TryGetValue(key, out value) || value == null) return 0;
            double result;
            return double.TryParse(Convert.ToString(value), System.Globalization.NumberStyles.Any,
                System.Globalization.CultureInfo.InvariantCulture, out result) ? result : 0;
        }

        private static string BuildPrompt(GenerationRequest request, string sceneJson)
        {
            return
                "You are editing an architectural visualization. " +
                "The first image is the Corona Beauty render and is the primary visual source. " +
                "The following images are technical references in order: Z-Depth, shading normals, " +
                "and an architecture protection mask. Use them as spatial/control references, not as " +
                "visible textures. Preserve camera composition, architectural geometry, facade layout, " +
                "window placement and all regions marked protected. Prefer appearance, lighting, material " +
                "and environment changes. Do not invent structural changes. " +
                "Requested edit strength: " +
                ClampStrength(request.Strength).ToString("0.00", System.Globalization.CultureInfo.InvariantCulture) +
                ".\n\nUSER PROMPT:\n" + request.Prompt +
                "\n\nSCENE CONTEXT (provider-agnostic JSON):\n" + sceneJson;
        }

        private static ProviderImagePart ReadImage(string role, string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                throw new NanoNetworkException("Image path is empty for " + role + ".", "INPUT_MISSING");
            if (!File.Exists(path))
                throw new FileNotFoundException("Input image not found for " + role + ".", path);

            var bytes = File.ReadAllBytes(path);
            if (bytes.Length == 0)
                throw new NanoNetworkException("Input image is empty for " + role + ".", "INPUT_EMPTY");

            return new ProviderImagePart
            {
                Role = role,
                MimeType = GuessMimeType(path),
                Base64Data = Convert.ToBase64String(bytes),
                SourcePath = path
            };
        }

        private static string GuessMimeType(string path)
        {
            var extension = Path.GetExtension(path);
            if (string.Equals(extension, ".jpg", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(extension, ".jpeg", StringComparison.OrdinalIgnoreCase))
                return "image/jpeg";
            if (string.Equals(extension, ".webp", StringComparison.OrdinalIgnoreCase))
                return "image/webp";
            return "image/png";
        }

        private static string ResolveOutputPath(GenerationRequest request, string mimeType)
        {
            if (!string.IsNullOrWhiteSpace(request.OutputPath))
                return request.OutputPath;

            var root = Path.GetDirectoryName(request.SceneJsonPath) ?? Path.GetTempPath();
            var extension = string.Equals(mimeType, "image/jpeg", StringComparison.OrdinalIgnoreCase)
                ? ".jpg" : ".png";
            return Path.Combine(root, "nanocorona_result" + extension);
        }

        private static double ClampStrength(double value)
        {
            if (value < 0.1) return 0.1;
            if (value > 1.0) return 1.0;
            return value;
        }

        private static void ValidateRequest(GenerationRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            RequireFile(request.SceneJsonPath, "Scene.json");
            RequireFile(request.BeautyPath, "Beauty");
            RequireFile(request.DepthPath, "Depth");
            RequireFile(request.NormalsPath, "Normals");
            RequireFile(request.ArchitectureMaskPath, "Architecture mask");
            if (string.IsNullOrWhiteSpace(request.Prompt))
                throw new NanoNetworkException("Prompt is empty.", "PROMPT_EMPTY");
        }

        private static void RequireFile(string path, string label)
        {
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
                throw new NanoNetworkException(label + " file is missing.", "INPUT_MISSING");
        }

        private static GenerationResult FailureResult(
            GenerationRequest request,
            ProviderResponse response,
            long durationMs)
        {
            return new GenerationResult
            {
                Success = false,
                Provider = "Gemini",
                Model = request.Model,
                ErrorCode = response.ErrorCode,
                ErrorMessage = response.ErrorMessage,
                HttpStatus = response.HttpStatus,
                RequestId = response.RequestId,
                Text = response.Text,
                DurationMs = durationMs
            };
        }
    }
}