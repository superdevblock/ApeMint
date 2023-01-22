import BigNumber from "bignumber.js";

export const mint = async (apeContract: any, account: any, cnt: any) => {
  const temp = await apeContract.methods.getNFTPrice().call()
  const price = new BigNumber(temp)
  const amount = price.multipliedBy(cnt)
  return apeContract.methods.mintNFT(cnt).send({ from: account, value: amount });
};
