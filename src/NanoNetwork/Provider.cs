using System.Threading;
using System.Threading.Tasks;

namespace NanoCorona.Network
{
    public interface IImageProvider
    {
        string Name { get; }
        Task<ProviderResponse> GenerateAsync(
            ProviderRequest request,
            string apiKey,
            NanoNetworkOptions options,
            CancellationToken cancellationToken);

        Task<ProviderResponse> AnalyzeAsync(
            ProviderRequest request,
            string apiKey,
            NanoNetworkOptions options,
            CancellationToken cancellationToken);
    }
}