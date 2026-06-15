using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PreferencesController : BaseCRUDController<Preference, PreferenceSearch, PreferenceInsertRequest, PreferenceUpdateRequest>
    {
        private readonly IPreferenceService _preferenceService;

        public PreferencesController(IPreferenceService service) : base(service)
        {
            _preferenceService = service;
        }

        [HttpGet("user/{userId}")]
        [Authorize]
        public async Task<IActionResult> GetUserPreference(int userId)
        {
            var preference = await _preferenceService.GetOrCreateUserPreference(userId);
            return Ok(preference);
        }

        [HttpPut("user/{userId}")]
        [Authorize]
        public async Task<IActionResult> UpdateUserPreferences(int userId, [FromBody] PreferenceUpdateRequest request)
        {
            var preference = await _preferenceService.UpdateUserPreferences(userId, request);
            return Ok(preference);
        }
    }
}