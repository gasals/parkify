using Microsoft.Extensions.Options;
using System.Net;
using System.Net.Mail;

namespace parkify.RabbitMQ
{
    public interface IEmailService
    {
        Task SendAsync(string to, string subject, string body);
    }

    public class SmtpEmailService : IEmailService
    {
        private readonly SmtpSettings _settings;

        public SmtpEmailService(IOptions<SmtpSettings> options)
        {
            _settings = options.Value;
        }

        public async Task SendAsync(string to, string subject, string body)
        {
            using var client = new SmtpClient(_settings.Host, _settings.Port)
            {
                Credentials = new NetworkCredential(_settings.Username, _settings.Password),
                EnableSsl = _settings.EnableSsl
            };

            var mail = new MailMessage
            {
                From = new MailAddress(_settings.FromAddress, _settings.FromName),
                Subject = subject,
                Body = body,
                IsBodyHtml = true
            };
            mail.To.Add(to);

            await client.SendMailAsync(mail);
        }
    }

    public class SmtpSettings
    {
        public string Host { get; set; } = "smtp.gmail.com";
        public int Port { get; set; } = 587;
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public bool EnableSsl { get; set; } = true;
        public string FromAddress { get; set; } = string.Empty;
        public string FromName { get; set; } = "Parkify";
    }
}
