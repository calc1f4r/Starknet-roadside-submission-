import { promises as fs } from "fs";
import path from "path";

export async function getCompiledCode(filename: string) {
  const sierraFilePath =""; // fill it with  sierra file path
  console.log("sierraFilePath=", sierraFilePath);
  // const casmFilePath = path.join(
  //   __dirname,
  //   `workshop/target/dev/${filename}.compiled_contract_class.json`
  // );
  // console.log("casmFilePath=", casmFilePath);
  const casmFilePath=""; // fill it casm file path
  const code = [sierraFilePath,casmFilePath].map(async (filePath) => {
    const file = await fs.readFile(filePath);
    return JSON.parse(file.toString("ascii"));
  });

  const [sierraCode,casmCode] = await Promise.all(code);

  return {
    sierraCode,
    casmCode,
  };
}
