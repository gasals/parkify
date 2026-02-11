using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IParkingSpotService : ICRUDService<ParkingSpot, ParkingSpotSearch, ParkingSpotInsertRequest, ParkingSpotUpdateRequest>
    {
        ParkingSpot SetAvailable(int id, bool isAvailable);
    }
}