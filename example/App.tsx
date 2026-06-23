import React from 'react';
import { Button, SafeAreaView, View } from 'react-native';
import MySDK from 'rn-flutter-sdk';

export default function App() {
  return (
    <SafeAreaView>
      <View style={{ padding: 24 }}>
        <Button
          title="Open Flutter Screen"
          onPress={() => MySDK.open({ userName: 'Nanu', userId: '123' })}
        />
      </View>
    </SafeAreaView>
  );
}
