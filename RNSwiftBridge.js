import { NativeModules } from "react-native";
//#region Code for object RNTwilioVoice
const NativeRNTwilioVoice = NativeModules.RNTwilioVoice;
const initWithAccessToken = async token => {
  return await NativeRNTwilioVoice.initWithAccessToken(token);
};
const configureCallKit = async params => {
  return await NativeRNTwilioVoice.configureCallKit(params);
};
const connect = async params => {
  return await NativeRNTwilioVoice.connect(params);
};
const disconnect = async () => {
  return await NativeRNTwilioVoice.disconnect();
};
const setMuted = async muted => {
  return await NativeRNTwilioVoice.setMuted(muted);
};
const setSpeakerPhone = async speakerPhone => {
  return await NativeRNTwilioVoice.setSpeakerPhone(speakerPhone);
};
const sendDigits = async digits => {
  return await NativeRNTwilioVoice.sendDigits(digits);
};
const unregister = async () => {
  return await NativeRNTwilioVoice.unregister();
};
const getActiveCall = async () => {
  return await NativeRNTwilioVoice.getActiveCall();
};
//#endregion
//#region Exports
export {
  initWithAccessToken,
  configureCallKit,
  connect,
  disconnect,
  setMuted,
  setSpeakerPhone,
  sendDigits,
  unregister,
  getActiveCall
};
//#endregion
