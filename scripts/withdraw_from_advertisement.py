from brownie import FiatStableCoinP2pSwap
from scripts.helpful_scripts import get_account


def withdraw_from_advertisement():
    account = get_account()
    p2p_swap = FiatStableCoinP2pSwap[-1]
    total_amount_withdraw = p2p_swap.advertise(0)[4] + p2p_swap.advertise(0)[5]
    p2p_swap.withdrawFromAdvertisement(
        0, total_amount_withdraw, {"from": account, "gas_limit": 2000000}
    )


def main():
    withdraw_from_advertisement()
