const {network} = require("hardhat")
const {CRYPTO_DEVS_ADDRESS, FAKE_NFT_MARKET_ADDRESS} = require("../helper")

module.exports = async function({deployments, getNamedAccounts}){
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const args = [FAKE_NFT_MARKET_ADDRESS, CRYPTO_DEVS_ADDRESS]
    log("Deploying------------------")
    // const fakeMarket = await deploy("FakeNFTMarket", {
    //     from: deployer,
    //     logs: true,
    //     // args: args,
    //     waitConfirmation: network.config.blockConfirmations || 1
    // })
    log("deploying DEVSDAO---------------")
    const devsDao = await deploy("DevsDao",{
        from: deployer,
        logs: true,
        args: args,
        waitConfirmation: network.config.blockConfirmations || 1
    })
    //console.log(`Fake nft market deployed to ${fakeMarket.address}`)
    console.log(`DevsDao deployed to ${devsDao.address}`)
}
module.exports.tags = ["all", "DevsDao"]