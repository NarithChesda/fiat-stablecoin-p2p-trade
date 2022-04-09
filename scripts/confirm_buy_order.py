from brownie import FiatStableCoinP2pSwap
from scripts.helpful_scripts import get_account, get_contract


def confirm_buy_order():
    account = get_account()
    p2p_swap = FiatStableCoinP2pSwap[-1]
    p2p_swap.confirmBuyOrder(
        0, True, {"from": account, "gas_limit": 20000000, "allow_revert": True}
    )


def main():
    confirm_buy_order()
