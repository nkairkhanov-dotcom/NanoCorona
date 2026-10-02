using System;
using System.Collections.Generic;

namespace NanoCorona.Network
{
    public sealed class GenerationRequest
    {
        public string SceneJsonPath { get; set; }
        public string BeautyPath { get; set; }
        public string DepthPath { get; set; }
        public string NormalsPath { get; set; }
        public string ArchitectureMaskPath { get; set; }
        public string EditJsonPath { get; set; }
        public string Prompt { get; set; }
        public double Strength { get; set; }
        public string Resolution { get; set; }
        public string Model { get; set; }
        public string OutputPath { get; set; }
    }

    public sealed class GenerationResult
    {
        public bool Success { get; set; }
        public string Provider { get; set; }
        public string Model { get; set; }
        public string ResultPath { get; set; }
        public string Text { get; set; }
        public string RequestId { get; set; }
        public string ErrorCode { get; set; }
        public string ErrorMessage { get; set; }
        public int HttpStatus { get; set; }
        public long DurationMs { get; set; }
    }

    public sealed class ProviderRequest
    {
        public string Provider { get; set; }
        public string Model { get; set; }
        public string Prompt { get; set; }
        public string Resolution { get; set; }
        public string AspectRatio { get; set; }
        public double Strength { get; set; }
        public IList<ProviderImagePart> Images { get; set; }
    }

    public sealed class ProviderImagePart
    {
        public string Role { get; set; }
        public string MimeType { get; set; }
        public string Base64Data { get; set; }
        public string SourcePath { get; set; }
    }

    public sealed class ProviderResponse
    {
        public bool Success { get; set; }
        public byte[] ImageBytes { get; set; }
        public string ImageMimeType { get; set; }
        public string Text { get; set; }
        public string RequestId { get; set; }
        public string ErrorCode { get; set; }
        public string ErrorMessage { get; set; }
        public int HttpStatus { get; set; }
        public string RawResponse { get; set; }
    }

    public sealed class NanoNetworkOptions
    {
        public TimeSpan Timeout { get; set; } = TimeSpan.FromMinutes(5);
        public int MaxRetries { get; set; } = 2;
        public string GeminiEndpoint { get; set; } =
            "https://generativelanguage.googleapis.com/v1beta/models/{0}:generateContent";
    }

    public sealed class NanoNetworkException : Exception
    {
        public string ErrorCode { get; private set; }
        public int HttpStatus { get; private set; }

        public NanoNetworkException(string message, string errorCode = null, int httpStatus = 0, Exception inner = null)
            : base(message, inner)
        {
            ErrorCode = errorCode;
            HttpStatus = httpStatus;
        }
    }

    public sealed class VisionQaRequest
    {
        public string SceneJsonPath { get; set; }
        public string SourceBeautyPath { get; set; }
        public string ResultPath { get; set; }
        public string ArchitectureMaskPath { get; set; }
        public string EditJsonPath { get; set; }
        public string Prompt { get; set; }
    }

    public sealed class VisionQaResult
    {
        public bool Success { get; set; }
        public double Confidence { get; set; }
        public bool ArchitecturePreserved { get; set; }
        public bool CameraPreserved { get; set; }
        public bool CompositionPreserved { get; set; }
        public bool EditSatisfied { get; set; }
        public string Severity { get; set; }
        public string Summary { get; set; }
        public string[] Violations { get; set; }
        public string RawText { get; set; }
        public string ErrorCode { get; set; }
        public string ErrorMessage { get; set; }
        public long DurationMs { get; set; }
    }
}
