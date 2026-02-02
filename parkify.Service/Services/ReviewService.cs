using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class ReviewService 
        : BaseCRUDService<Review, ReviewSearch, Database.Review, ReviewInsertRequest, ReviewUpdateRequest>,
          IReviewService
    {
        public ReviewService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Review> AddFilter(ReviewSearch search, IQueryable<Database.Review> query)
        {
            query = base.AddFilter(search, query);

            if (search?.ParkingZoneId.HasValue == true)
            {
                query = query.Where(x => x.ParkingZoneId == search.ParkingZoneId);
            }

            if (search?.UserId.HasValue == true)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (search?.RatingMin.HasValue == true)
            {
                query = query.Where(x => x.Rating >= search.RatingMin);
            }

            return query;
        }
    }
}
