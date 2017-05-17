
#ifndef BRIDGE_START_H
#define BRIDGE_START_H

#include <jni.h>

int start();

JNIEXPORT jstring JNICALL
Java_org_fallenworld_darkgalgame_MainActivity_entry(JNIEnv *env, jobject thiz);

JNIEnv *getEnv();

#endif //BRIDGE_START_H
