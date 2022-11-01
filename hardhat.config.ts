import * as dotenv from 'dotenv'
dotenv.config()
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  defaultNetwork: "mumbai",
  networks: {
    hardhat: {
    },
    mumbai: {
      url: process.env.MUMBAI_RPC_URL,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
