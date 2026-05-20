using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IParkingZoneService : ICRUDService<ParkingZone, ParkingZoneSearch, ParkingZoneInsertRequest, ParkingZoneUpdateRequest>
    {
        ParkingZone Delete(int id);
        List<ParkingZone> GetRecommendations(int userId, int count = 5);
    }
}