using MapsterMapper;
using parkify.Model.Exceptions;
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

        public override void BeforeInsert(ReviewInsertRequest request, Database.Review entity)
        {
            var hasCompletedReservation = Context.Reservations.Any(x =>
                x.UserId == request.UserId &&
                x.ParkingZoneId == request.ParkingZoneId &&
                x.Status == Database.ReservationStatus.Completed);

            if (!hasCompletedReservation)
                throw new UserException("Recenziju možete ostaviti tek nakon završene rezervacije u ovoj zoni.");

            if (Context.Reviews.Any(x => x.UserId == request.UserId && x.ParkingZoneId == request.ParkingZoneId))
                throw new UserException("Ve? ste ocijenili ovu zonu.");

            if (string.IsNullOrWhiteSpace(request.ReviewText))
                throw new UserException("Recenzija je obavezna.");

            entity.ReviewText = request.ReviewText.Trim();

            base.BeforeInsert(request, entity);
        }

        public override void BeforeUpdate(ReviewUpdateRequest request, Database.Review entity)
        {
            if (request.ReviewText != null)
            {
                if (string.IsNullOrWhiteSpace(request.ReviewText))
                    throw new UserException("Recenzija ne može biti prazna.");

                entity.ReviewText = request.ReviewText.Trim();
            }

            base.BeforeUpdate(request, entity);
        }
    }
}
