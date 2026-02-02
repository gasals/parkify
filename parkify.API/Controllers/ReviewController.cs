using Microsoft.AspNetCore.Mvc;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    public class ReviewController : BaseCRUDController<Review, ReviewSearch, ReviewInsertRequest, ReviewUpdateRequest>
    {
        public ReviewController(IReviewService service) : base(service)
        {
        }
    }
}
