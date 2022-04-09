from math import remainder
from brownie import FiatStableCoinP2pSwap, MockDAI, config, network
from web3 import Web3

from scripts.helpful_scripts import get_account, get_contract


def main():
    # deploy p2p-swap
    account = get_account()
    fiat_stable_coin_p2p_swap = FiatStableCoinP2pSwap.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    # deploy mock dai
    mock_dai = get_contract("fau_token")

    print(f"Mock Dai Address :{mock_dai.address}")

    fiat_stable_coin_p2p_swap.addAllowedTokens(mock_dai.address, {"from": account})

    amount = Web3.toWei(100, "ether")

    mock_dai.approve(fiat_stable_coin_p2p_swap.address, amount, {"from": account})

    fiat_stable_coin_p2p_swap.createSellAdvertise(
        mock_dai.address,
        amount,
        0,
        amount - (amount / 1000),
        "0.01",
        {"from": account, "gas_limit": 2000000, "allow_revert": True},
    )

    print(f"Advertise : {fiat_stable_coin_p2p_swap.viewAdvertisement(0)}")

    print(Web3.fromWei(mock_dai.balanceOf(fiat_stable_coin_p2p_swap.address), "ether"))

    fiat_stable_coin_p2p_swap.sendBuyOrder(0, amount / 2, {"from": account})

    fiat_stable_coin_p2p_swap.confirmBuyOrder(0, True, {"from": account})

    print(Web3.fromWei(mock_dai.balanceOf(fiat_stable_coin_p2p_swap.address), "ether"))

    # remaining_balance = feeDeposited[5] + advertisingBalance[4]
    remaining_balance = (
        fiat_stable_coin_p2p_swap.advertise(0)[4]
        + fiat_stable_coin_p2p_swap.advertise(0)[5]
    )
    print(f"advertising balance: {fiat_stable_coin_p2p_swap.advertise(0)[4]}")
    print(f"remaining deposit: {fiat_stable_coin_p2p_swap.advertise(0)[5]}")
    print(f"remaining balance: {remaining_balance}")

    fiat_stable_coin_p2p_swap.withdrawFromAdvertisement(
        0,
        remaining_balance,
        {"from": account, "gas_limit": 2000000, "allow_revert": True},
    )
