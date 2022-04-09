// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Deposit Token -- Done
// Deposit Platform Fee -- Done
// CreateSellAdvertisement -- Done
// SenderBuyOrder -- Done
// CancelBuyOrder -- Done
// WithdrawFromAdvertisement -- Done
// SetPlatformFee -- Done
// AddAllowedTokens -- Done
// ProcessingFee -- Done
// HandleAppeal -- Done
// VaultWithdraw -- Done

contract FiatStableCoinP2pSwap is Ownable {
    // mapping user_address => numberOfAdvertisements
    mapping(address => uint256) public numberOfAdvertisements;
    // mapping token_address => vault
    mapping(address => uint256) public vault;

    struct Advertise {
        bool activeBuyOrder;
        bool advertisingStatus;
        bool appealing;
        address user;
        uint256 advertisingBalance;
        uint256 feeDeposited;
        uint256 id;
        string rate;
        address token;
        uint256 buyOrderAmountRequested;
        uint256 minimumOrderRequest;
        uint256 maximumOrderRequest;
        uint256 middleManBalance;
        address buyer;
    }

    uint256 public platformFee;
    address[] public users;
    address[] public allowedTokens;
    Advertise[] public advertise;
    uint256 public advertisingLimit;

    constructor() public {
        platformFee = 1000;
        advertisingLimit = 2;
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function setAdvertisingStatus(uint256 _id, bool _status) public {
        require(advertise[_id].user == msg.sender, "msg.sender isn't the owner of the advertisement!");
        advertise[_id].advertisingStatus = _status;
    }

    function createSellAdvertise(
        address _token,
        uint256 _amount,
        uint256 _min,
        uint256 _max,
        string memory _rate
    ) public {
        require(_amount > 0, "Amount cannot be 0");
        require(tokenIsAllowed(_token), "Token is not allowed!");
        require(
            numberOfAdvertisements[msg.sender] < advertisingLimit,
            "Each user only have 2 advertising limit!"
        );

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        numberOfAdvertisements[msg.sender] =
            numberOfAdvertisements[msg.sender] +
            1;
        Advertise memory ads;
        ads.token = _token;
        ads.activeBuyOrder = false;
        ads.feeDeposited = _amount / platformFee;
        ads.advertisingBalance = _amount - ads.feeDeposited;
        ads.advertisingStatus = true;
        ads.appealing = false;
        ads.id = advertise.length;
        ads.rate = _rate;
        ads.user = msg.sender;
        ads.buyOrderAmountRequested = 0;
        ads.minimumOrderRequest = _min;
        ads.maximumOrderRequest = _max;
        ads.middleManBalance = 0;
        advertise.push(ads);
        if (numberOfAdvertisements[msg.sender] == 1) {
            users.push(msg.sender);
        }
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function setPlatformFee(uint256 _fee) public onlyOwner {
        platformFee = _fee;
    }

    function sendBuyOrder(uint256 _id, uint256 _amount) public {
        require(
            !advertise[_id].activeBuyOrder,
            "This Advertise is busy at the moment!"
        );
        require(
            _amount > advertise[_id].minimumOrderRequest &&
                _amount <= advertise[_id].advertisingBalance,
            "_amount is bigger than advertising Balance"
        );
        advertise[_id].activeBuyOrder = true;
        advertise[_id].buyOrderAmountRequested = _amount;
        advertise[_id].middleManBalance = advertise[_id]
            .buyOrderAmountRequested;
        advertise[_id].advertisingBalance =
            advertise[_id].advertisingBalance -
            advertise[_id].middleManBalance;
        advertise[_id].buyer = msg.sender;
    }

    function confirmBuyOrder(uint256 _id, bool _confirmation) public {
        require(
            advertise[_id].user == msg.sender,
            "Msg.sender is not the advertisment owner!"
        );

        if (_confirmation) {
            IERC20(advertise[_id].token).transfer(
                advertise[_id].buyer,
                advertise[_id].middleManBalance
            );
            processingFee(_id);
            // if advertising balance is 0, pop the advertise
            if (advertise[_id].advertisingBalance == 0) {
                advertise[_id] = advertise[advertise.length - 1];
                advertise.pop();
                numberOfAdvertisements[msg.sender] =
                    numberOfAdvertisements[msg.sender] -
                    1;
            } else {
                advertise[_id].middleManBalance = 0;
                advertise[_id].activeBuyOrder = false;
                advertise[_id].buyOrderAmountRequested = 0;
                advertise[_id].buyer = address(0);
            }
        } else {
            advertise[_id].appealing = true;
        }
    }

    function cancelBuyOrder(uint256 _id) public {
        require(
            advertise[_id].buyer == msg.sender || owner() == msg.sender,
            "msg.sender is not buyer!"
        );
        advertise[_id].activeBuyOrder = false;
        advertise[_id].buyer = address(0);
        advertise[_id].advertisingBalance =
            advertise[_id].advertisingBalance +
            advertise[_id].middleManBalance;
        advertise[_id].middleManBalance = 0;
        advertise[_id].buyOrderAmountRequested = 0;
        advertise[_id].appealing = false;
    }

    function withdrawFromAdvertisement(uint256 _id, uint256 _amount) public {
        require(advertise[_id].user == msg.sender, "msg.seder is not user");
        require(
            _amount <=
                advertise[_id].advertisingBalance + advertise[_id].feeDeposited,
            "amount is bigger than advertising balance"
        );

        if (
            advertise[_id].advertisingBalance + advertise[_id].feeDeposited ==
            _amount
        ) {
            IERC20(advertise[_id].token).transfer(msg.sender, _amount);

            advertise[_id] = advertise[advertise.length - 1];
            advertise.pop();
            numberOfAdvertisements[msg.sender] =
                numberOfAdvertisements[msg.sender] -
                1;
        } else {
            IERC20(advertise[_id].token).transfer(msg.sender, _amount);

            advertise[_id].advertisingBalance =
                advertise[_id].advertisingBalance -
                _amount;
        }
    }

    function processingFee(uint256 _id) internal {
        uint256 fee = advertise[_id].buyOrderAmountRequested / platformFee;
        address token = advertise[_id].token;
        vault[token] = vault[token] + fee;
        advertise[_id].feeDeposited = advertise[_id].feeDeposited - fee;
    }

    function vaultWithdraw(address _token) public onlyOwner {
        uint256 amount = vault[_token];
        IERC20(_token).transfer(owner(), amount);
        vault[_token] = 0;
    }

    function viewAdvertisement(uint256 _id)
        public
        view
        returns (
            uint256 id, // id
            address user, // user
            address token, // token
            bool advertisingStatus, // advertisingStatus
            bool activeBuyOrder, // activeBuyOrder
            bool appealing, // appealing
            uint256 advertisingBalance, // advertisingBalance
            uint256 feeDeposited, // feeDeposited
            uint256 middleManBalance, // middleManBalance
            uint256 min, // min
            uint256 max, // max
            uint256 buyOrderAmountRequested, // buyOrderAmountRequested
            address buyer // buyer
        )
    {
        id = advertise[_id].id;
        user = advertise[_id].user;
        token = advertise[_id].token;
        advertisingStatus = advertise[_id].advertisingStatus;
        advertisingBalance = advertise[_id].advertisingBalance;
        activeBuyOrder = advertise[_id].activeBuyOrder;
        appealing = advertise[_id].appealing;

        feeDeposited = advertise[_id].feeDeposited;
        middleManBalance = advertise[_id].middleManBalance;
        min = advertise[_id].minimumOrderRequest;
        max = advertise[_id].maximumOrderRequest;
        buyOrderAmountRequested = advertise[_id].buyOrderAmountRequested;
        buyer = advertise[_id].buyer;
    }

    function viewTotalAds() public view returns (uint256) {
        return advertise.length;
    }

    function handleAppeal(uint256 _id, bool _conclusion) public onlyOwner {
        // if true, send token to buyer else reset the buy order for seller
        if (_conclusion) {
            IERC20(advertise[_id].token).transfer(
                advertise[_id].buyer,
                advertise[_id].buyOrderAmountRequested
            );
            processingFee(_id);
            if (
                advertise[_id].buyOrderAmountRequested ==
                advertise[_id].advertisingBalance
            ) {
                numberOfAdvertisements[advertise[_id].user] =
                    numberOfAdvertisements[advertise[_id].user] -
                    1;
                advertise[_id] = advertise[advertise.length - 1];
                advertise.pop();
            } else {
                advertise[_id].activeBuyOrder = false;
                advertise[_id].buyOrderAmountRequested = 0;
                advertise[_id].buyer = address(0);
                advertise[_id].advertisingBalance =
                    advertise[_id].advertisingBalance -
                    advertise[_id].buyOrderAmountRequested;
                advertise[_id].middleManBalance = 0;
                advertise[_id].appealing = false;
            }
        } else {
            cancelBuyOrder(_id);
        }
    }
}
