import { NativeModules, NativeEventEmitter } from "react-native";
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
//#region events for object RNTwilioVoice
var _getNativeRNTwilioVoiceEventEmitter = null;
const getNativeRNTwilioVoiceEventEmitter = () => {
  if (!_getNativeRNTwilioVoiceEventEmitter)
    getNativeRNTwilioVoiceEventEmitter = new NativeEventEmitter(
      NativeRNTwilioVoice
    );
  return _getNativeRNTwilioVoiceEventEmitter;
};
const subscribeToconnectionDidConnect = cb => {
  return getNativeRNTwilioVoiceEventEmitter().addListener(
    "connectionDidConnect",
    cb
  );
};
const subscribeToconnectionDidDisconnect = cb => {
  return getNativeRNTwilioVoiceEventEmitter().addListener(
    "connectionDidDisconnect",
    cb
  );
};
const subscribeTocallRejected = cb => {
  return getNativeRNTwilioVoiceEventEmitter().addListener("callRejected", cb);
};
const subscribeTodeviceReady = cb => {
  return getNativeRNTwilioVoiceEventEmitter().addListener("deviceReady", cb);
};
const subscribeTodeviceNotReady = cb => {
  return getNativeRNTwilioVoiceEventEmitter().addListener("deviceNotReady", cb);
};
//#endregion
//#region Event marshalling object
const RNSEvents = {
  connectionDidConnect: subscribeToconnectionDidConnect,
  connectionDidDisconnect: subscribeToconnectionDidDisconnect,
  callRejected: subscribeTocallRejected,
  deviceReady: subscribeTodeviceReady,
  deviceNotReady: subscribeTodeviceNotReady
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
  getActiveCall,
  subscribeToconnectionDidConnect,
  subscribeToconnectionDidDisconnect,
  subscribeTocallRejected,
  subscribeTodeviceReady,
  subscribeTodeviceNotReady,
  RNSEvents
};
//#endregion
