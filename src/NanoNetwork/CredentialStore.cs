using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace NanoCorona.Network
{
    public static class CredentialStore
    {
        private const string Prefix = "NanoCorona:";
        private static readonly byte[] Entropy = Encoding.UTF8.GetBytes(Prefix + "Gemini");

        public static string GetDefaultPath()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            return Path.Combine(appData, "NanoCorona", "credentials.bin");
        }

        public static void SaveGeminiApiKey(string apiKey, string path = null)
        {
            if (string.IsNullOrWhiteSpace(apiKey))
                throw new ArgumentException("API key is empty.", nameof(apiKey));

            path = path ?? GetDefaultPath();
            var directory = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(directory))
                Directory.CreateDirectory(directory);

            var plain = Encoding.UTF8.GetBytes(apiKey);
            var encrypted = ProtectedData.Protect(plain, Entropy, DataProtectionScope.CurrentUser);
            File.WriteAllBytes(path, encrypted);
        }

        public static string LoadGeminiApiKey(string path = null)
        {
            path = path ?? GetDefaultPath();
            if (!File.Exists(path))
                return null;

            var encrypted = File.ReadAllBytes(path);
            var plain = ProtectedData.Unprotect(encrypted, Entropy, DataProtectionScope.CurrentUser);
            return Encoding.UTF8.GetString(plain);
        }

        public static void Delete(string path = null)
        {
            path = path ?? GetDefaultPath();
            if (File.Exists(path))
                File.Delete(path);
        }
    }
}