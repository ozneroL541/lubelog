using Microsoft.Extensions.Diagnostics.HealthChecks;
using Npgsql;

namespace CarCareTracker.Helper
{
    public class AppReadinessHealthCheck : IHealthCheck
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _webHostEnvironment;

        public AppReadinessHealthCheck(IConfiguration configuration, IWebHostEnvironment webHostEnvironment)
        {
            _configuration = configuration;
            _webHostEnvironment = webHostEnvironment;
        }

        public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
        {
            try
            {
                await EnsureDirectoryIsWritable(Path.Combine(_webHostEnvironment.ContentRootPath, "data", "temp"), cancellationToken);

                var dataProtectionKeysPath = _configuration["LUBELOGGER_DATAPROTECTION_KEYS_PATH"];
                if (!string.IsNullOrWhiteSpace(dataProtectionKeysPath))
                {
                    await EnsureDirectoryIsWritable(dataProtectionKeysPath, cancellationToken);
                }

                var postgresConnection = _configuration["POSTGRES_CONNECTION"];
                if (!string.IsNullOrWhiteSpace(postgresConnection))
                {
                    await using var connection = new NpgsqlConnection(postgresConnection);
                    await connection.OpenAsync(cancellationToken);
                    await using var command = new NpgsqlCommand("SELECT 1", connection);
                    await command.ExecuteScalarAsync(cancellationToken);
                }

                return HealthCheckResult.Healthy("Application storage and database dependencies are available.");
            }
            catch (Exception ex)
            {
                return HealthCheckResult.Unhealthy("Application readiness checks failed.", ex);
            }
        }

        private static async Task EnsureDirectoryIsWritable(string directoryPath, CancellationToken cancellationToken)
        {
            Directory.CreateDirectory(directoryPath);

            var healthCheckFilePath = Path.Combine(directoryPath, $".healthcheck-{Guid.NewGuid():N}");
            await File.WriteAllTextAsync(healthCheckFilePath, "ok", cancellationToken);
            File.Delete(healthCheckFilePath);
        }
    }
}
