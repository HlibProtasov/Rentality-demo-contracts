import RentCarJSON from "../ContractExport";

const RequestTile = (data) => {
  const approveRentCarRequest = async () => {
    try {
      const ethers = require("ethers");
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      let transaction = await contract.approveRentCar(data.data.tokenId);
      await transaction.wait();

      alert("Car rent approved!");
      window.location.replace("/");
    } catch (e) {
      alert("approveRentCar error" + e);
    }
  };

  const rejectRentCarRequest = async () => {
    try {
      const ethers = require("ethers");
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      let transaction = await contract.rejectRentCar(data.data.tokenId);
      await transaction.wait();

      alert("Car rent rejected!");
      window.location.replace("/");
    } catch (e) {
      alert("rejectRentCar error" + e);
    }
  };

  const formatAddress = (address) => {
    if (address == null || address.length < 10) return address;
    return address.substr(0, 5) + ".." + address.substr(address.length - 5);
  };

  return (
    <div className="border-2 flex flex-col items-center rounded-md w-full shadow-2xl">
      <div className="flex flex-row items-center mt-2 mx-4 w-full">
        <img
          src={data.data.image}
          alt=""
          className="ml-4 w w-16 h-16 rounded-sm object-cover"
        />
        <div className="text-white w-full">
          <strong className="text-1">{data.data.name}</strong>
          <p className="display-inline">
            <strong className="text-sm">
              from {formatAddress(data.data.renter)}
            </strong>
            <strong className="text-sm">
              {" "}
              for {data.data.daysForRent} day(s)
            </strong>
          </p>
          <p className="display-inline"></p>
          <p className="display-inline">
            <strong className="text-2">for ${data.data.totalPrice}</strong>
          </p>
        </div>
      </div>
      <div className="flex flex-row items-center mt-2 mb-2">
        <button
          className="approveButton bg-blue-500 hover:bg-blue-700 text-white font-bold mx-5 py-2 px-4 rounded text-sm"
          onClick={() => approveRentCarRequest()}
        >
          Approve
        </button>
        <button
          className="approveButton bg-red-500 hover:bg-red-700 text-white font-bold mx-5 py-2 px-4 rounded text-sm"
          onClick={() => rejectRentCarRequest()}
        >
          Reject
        </button>
      </div>
    </div>
  );
};

export default RequestTile;
