// import

const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

//main function creation

//calling the main function

// function deployFunc(hre) {
//     console.log("Hi")
// Headers.getNamedAccounts()
// Headers.deployments()
// }

// module.exports.default = deployFunc

// module.exports = async (hre) => {
//     const {getNamedAccounts, deployments} = hre

// }

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    //If chainId is X use add Y
    //If chainId is Z use add A

    // const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    //Mock contract: If the contract doesn't exist, we display a minimal version for our local testing

    // well what happens when we want to change chanins
    // when going for localhost or hardhat network we want to use mock
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, //put price feed address,
        log: true,
        waitConfirmation: network.config.blockConfermations || 1,
    })

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, args)
    }
    log(
        "-------------------------------------------------------------------------------------"
    )
}

module.exports.tags = ["all", "fundme"]
