from email.headerregistry import Address
from web3 import Web3
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONTMENTS, get_account
from brownie import (
    FiatStableCoinP2pSwap,
    MockERC20,
    accounts,
    network,
    config,
    exceptions,
)
import pytest


def test_add_allowed_tokens():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONTMENTS:
        pytest.skip("Only for local test!")
    account = get_account()
    user = get_account(index=1)
    fiat_stable_coin_p2p_swap = FiatStableCoinP2pSwap.deploy({"from": account})
    mock_erc20 = MockERC20.deploy({"from": account})

    # Act
    fiat_stable_coin_p2p_swap.addAllowedTokens(mock_erc20.address, {"from": account})
    # Assert
    assert fiat_stable_coin_p2p_swap.allowedTokens(0) == mock_erc20.address
    assert fiat_stable_coin_p2p_swap.allowedTokens().length == 1
    with pytest.raises(exceptions.VirtualMachineError):
        fiat_stable_coin_p2p_swap.addAllowedTokens(mock_erc20.address, {"from": user})


def test_create_sell_advertise():

    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONTMENTS:
        pytest.skip("Only for local test!")
    account = get_account()
    user = get_account(index=1)
    fiat_stable_coin_p2p_swap = FiatStableCoinP2pSwap.deploy({"from": account})
    mock_erc20 = MockERC20.deploy({"from": account})
    fiat_stable_coin_p2p_swap.addAllowedTokens(mock_erc20.address, {"from": account})
    amount = Web3.toWei(100, "ether")
    mock_erc20.approve(fiat_stable_coin_p2p_swap.address, amount, {"from": account})
    # Act
    fiat_stable_coin_p2p_swap.createSellAdvertise(
        mock_erc20.address, amount, 0, amount, "0.01", {"from": account}
    )

    # Assert
    # struct Advertise {
    #     bool activeBuyOrder;
    #     bool advertisingStatus;
    #     bool appealing;
    #     address user;
    #     uint256 advertisingBalance;
    #     uint256 feeDeposited;
    #     uint256 id;
    #     string rate;
    #     address token;
    #     uint256 buyOrderAmountRequested;
    #     uint256 minimumOrderRequest;
    #     uint256 maximumOrderRequest;
    #     uint256 middleManBalance;
    #     address buyer;
    # }
    assert fiat_stable_coin_p2p_swap.advertise(0)[3] == account
    assert fiat_stable_coin_p2p_swap.advertise(0)[0] == False
    assert fiat_stable_coin_p2p_swap.advertise(0)[1] == True
    assert fiat_stable_coin_p2p_swap.advertise(0)[2] == False
    assert fiat_stable_coin_p2p_swap.advertise(0)[4] == amount - (
        amount / fiat_stable_coin_p2p_swap.platformFee()
    )
    assert (
        fiat_stable_coin_p2p_swap.advertise(0)[5]
        == amount / fiat_stable_coin_p2p_swap.platformFee()
    )
    assert fiat_stable_coin_p2p_swap.advertise(0)[6] == 0
    assert fiat_stable_coin_p2p_swap.advertise(0)[7] == "0.01"
    assert fiat_stable_coin_p2p_swap.advertise(0)[8] == mock_erc20.address
    assert fiat_stable_coin_p2p_swap.advertise(0)[9] == 0
    assert fiat_stable_coin_p2p_swap.advertise(0)[10] == 0
    assert fiat_stable_coin_p2p_swap.advertise(0)[11] == amount
    assert fiat_stable_coin_p2p_swap.advertise(0)[12] == 0

    return fiat_stable_coin_p2p_swap, mock_erc20


def test_set_advertising_status():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONTMENTS:
        pytest.skip("Only for local test!")

    account = get_account()
    p2p_swap, mock_erc20 = test_create_sell_advertise()
    # Act
    p2p_swap.setAdvertisingStatus(0, False, {"from": account})
    # Assert
    assert p2p_swap.advertise(0)[1] == False


def test_send_buy_order():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONTMENTS:
        pytest.skip("Only for local test!")

    user = get_account(index=1)
    p2p_swap, mock_erc20 = test_create_sell_advertise()
    amount = Web3.toWei(10, "ether")
    # Act
    p2p_swap.sendBuyOrder(0, amount, {"from": user})

    # Assert
    assert p2p_swap.advertise(0)[0] == True
    assert p2p_swap.advertise(0)[13] == user
