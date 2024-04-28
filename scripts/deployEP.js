/* global ethers hre */

const { ethers } = require("hardhat")

/* eslint prefer-const: "off" */
const EP = "0x7220E5e1d3C83306515Db160bFed551D450F0D45"
const PM = "0x99c764EF714014e9bFbD26A59772625C8A09e14D"
async function deployEP(){
    const EntryPoint = await ethers.getContractFactory('EntryPoint')
    const entryPoint = await EntryPoint.deploy()
    await entryPoint.deployed()
    console.log('EntryPoint deployed:', entryPoint.address)

    const Paymaster = await ethers.getContractFactory('Paymaster')
    const paymaster = await Paymaster.deploy()
    await paymaster.deployed()
    console.log("paymaster depolyed to:", paymaster.address)
}

deployEP()