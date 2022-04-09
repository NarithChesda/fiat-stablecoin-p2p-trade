from brownie import FiatStableCoinP2pSwap, network
from web3 import Web3
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONTMENTS,
    get_account,
    get_contract,
)


def create_sell_advertise():
    account = get_account()
    fau_token = get_contract("fau_token")

    p2p_swap = FiatStableCoinP2pSwap[-1]
    amount = Web3.toWei(100, "ether")
    fau_token.approve(p2p_swap.address, amount, {"from": account})
    p2p_swap.createSellAdvertise(
        fau_token.address,
        amount,
        0,
        amount - (amount / 1000),
        "0.01",
        {"from": account, "gas_limit": 2000000, "allow_revert": True},
    )


def main():
    create_sell_advertise()
