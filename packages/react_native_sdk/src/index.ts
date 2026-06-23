import { NativeModules } from 'react-native';

export type OpenArgs = {
  userName: string;
  userId: string;
  [extra: string]: string;
};

const { MySDKModule } = NativeModules;

export default {
  open(data: OpenArgs): void {
    MySDKModule.open(data);
  },
};
