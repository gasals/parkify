using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;

namespace parkify.API.Controllers
{
    public class ReviewController : BaseCRUDController<Review, ReviewSearch, ReviewInsertRequest, ReviewUpdateRequest>
    {
        public ReviewController(IReviewService service) : base(service)
        {
        }

        [HttpGet]
        public override PagedResult<Review> GetList([FromQuery] ReviewSearch searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override Review GetById(int id)
        {
            var review = base.GetById(id);

            if (!IsCurrentUserAdmin() && review.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovoj recenziji.");

            return review;
        }

        [HttpPost]
        public override Review Insert([FromBody] ReviewInsertRequest request)
        {
            var currentUserId = GetCurrentUserIdOrThrow();
            if (!IsCurrentUserAdmin())
            {
                request.UserId = currentUserId;
            }
            else if (request.UserId <= 0)
            {
                request.UserId = currentUserId;
            }

            return base.Insert(request);
        }

        [HttpPut("{id}")]
        public override Review Update(int id, [FromBody] ReviewUpdateRequest request)
        {
            if (!IsCurrentUserAdmin())
            {
                var review = base.GetById(id);
                if (review.UserId != GetCurrentUserIdOrThrow())
                    throw new UnauthorizedAccessException("Nemate pravo izmjene ove recenzije.");
            }

            return base.Update(id, request);
        }
    }
}
