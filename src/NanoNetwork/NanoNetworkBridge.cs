using System;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;

namespace NanoCorona.Network
{
    public sealed class NanoNetworkBridge
    {
        private sealed class Job
        {
            public readonly CancellationTokenSource Cancellation = new CancellationTokenSource();
            public volatile string State = "Queued";
            public volatile int Progress = 0;
            public string ResultPath;
            public string ErrorCode;
            public string ErrorMessage;
            public long DurationMs;
        }

        private static readonly ConcurrentDictionary<string, Job> Jobs =
            new ConcurrentDictionary<string, Job>();

        private readonly NanoNetworkClient _client;

        public NanoNetworkBridge()
        {
            _client = new NanoNetworkClient();
        }

        public bool HasGeminiApiKey()
        {
            try
            {
                return !string.IsNullOrWhiteSpace(CredentialStore.LoadGeminiApiKey());
            }
            catch
            {
                return false;
            }
        }

        public void SaveGeminiApiKey(string apiKey)
        {
            CredentialStore.SaveGeminiApiKey(apiKey);
        }

        public void DeleteGeminiApiKey()
        {
            CredentialStore.Delete();
        }

        public string StartGeneration(
            string sceneJsonPath,
            string beautyPath,
            string depthPath,
            string normalsPath,
            string architectureMaskPath,
            string prompt,
            double strength,
            string resolution,
            string model,
            string outputPath,
            string apiKeyOverride)
        {
            var apiKey = string.IsNullOrWhiteSpace(apiKeyOverride)
                ? CredentialStore.LoadGeminiApiKey()
                : apiKeyOverride;

            if (string.IsNullOrWhiteSpace(apiKey))
                throw new NanoNetworkException(
                    "Gemini API key is not configured.",
                    "AUTH_MISSING");

            var request = new GenerationRequest
            {
                SceneJsonPath = sceneJsonPath,
                BeautyPath = beautyPath,
                DepthPath = depthPath,
                NormalsPath = normalsPath,
                ArchitectureMaskPath = architectureMaskPath,
                Prompt = prompt,
                Strength = strength,
                Resolution = resolution,
                Model = string.IsNullOrWhiteSpace(model)
                    ? "gemini-3-pro-image"
                    : model,
                OutputPath = outputPath
            };

            var jobId = Guid.NewGuid().ToString("N");
            var job = new Job();

            if (!Jobs.TryAdd(jobId, job))
                throw new NanoNetworkException(
                    "Could not create generation job.",
                    "JOB_CREATE_FAILED");

            RunJob(job, request, apiKey);
            return jobId;
        }

        public void CancelGeneration(string jobId)
        {
            Job job;
            if (!Jobs.TryGetValue(jobId, out job))
                return;

            job.Cancellation.Cancel();
            job.State = "Canceling";
        }

        public string GetJobState(string jobId)
        {
            Job job;
            return Jobs.TryGetValue(jobId, out job) ? job.State : "Unknown";
        }

        public int GetJobProgress(string jobId)
        {
            Job job;
            return Jobs.TryGetValue(jobId, out job) ? job.Progress : 0;
        }

        public string GetJobResultPath(string jobId)
        {
            Job job;
            return Jobs.TryGetValue(jobId, out job) ? (job.ResultPath ?? "") : "";
        }

        public string GetJobErrorCode(string jobId)
        {
            Job job;
            return Jobs.TryGetValue(jobId, out job) ? (job.ErrorCode ?? "") : "";
        }

        public string GetJobErrorMessage(string jobId)
        {
            Job job;
            return Jobs.TryGetValue(jobId, out job) ? (job.ErrorMessage ?? "") : "";
        }

        public long GetJobDurationMs(string jobId)
        {
            Job job;
            return Jobs.TryGetValue(jobId, out job) ? job.DurationMs : 0;
        }

        public bool IsJobFinished(string jobId)
        {
            var state = GetJobState(jobId);
            return state == "Succeeded" ||
                   state == "Failed" ||
                   state == "Canceled" ||
                   state == "Unknown";
        }

        public void ForgetJob(string jobId)
        {
            Job job;
            if (Jobs.TryRemove(jobId, out job))
            {
                try { job.Cancellation.Dispose(); } catch { }
            }
        }

        private void RunJob(
            Job job,
            GenerationRequest request,
            string apiKey)
        {
            Task.Run(async () =>
            {
                try
                {
                    job.State = "Preparing";
                    job.Progress = 10;

                    job.State = "Uploading";
                    job.Progress = 25;

                    var task = _client.GenerateAsync(
                        request,
                        apiKey,
                        job.Cancellation.Token);

                    job.State = "Generating";
                    job.Progress = 50;

                    var result = await task.ConfigureAwait(false);
                    job.DurationMs = result.DurationMs;

                    if (result.Success)
                    {
                        job.State = "Saving";
                        job.Progress = 90;
                        job.ResultPath = result.ResultPath;
                        job.Progress = 100;
                        job.State = "Succeeded";
                    }
                    else if (string.Equals(
                        result.ErrorCode,
                        "CANCELED",
                        StringComparison.OrdinalIgnoreCase))
                    {
                        job.ErrorCode = result.ErrorCode;
                        job.ErrorMessage = result.ErrorMessage;
                        job.Progress = 0;
                        job.State = "Canceled";
                    }
                    else
                    {
                        job.ErrorCode = result.ErrorCode;
                        job.ErrorMessage = result.ErrorMessage;
                        job.Progress = 0;
                        job.State = "Failed";
                    }
                }
                catch (OperationCanceledException)
                {
                    job.ErrorCode = "CANCELED";
                    job.ErrorMessage = "Generation was canceled.";
                    job.Progress = 0;
                    job.State = "Canceled";
                }
                catch (Exception ex)
                {
                    job.ErrorCode = ex is NanoNetworkException
                        ? ((NanoNetworkException)ex).ErrorCode
                        : "BRIDGE_ERROR";
                    job.ErrorMessage = ex.Message;
                    job.Progress = 0;
                    job.State = "Failed";
                }
                finally
                {
                    try { job.Cancellation.Dispose(); } catch { }
                }
            });
        }
    }
}