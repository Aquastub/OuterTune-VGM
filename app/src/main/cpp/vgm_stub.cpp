#include <jni.h>
#include <android/log.h>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "VGM", __VA_ARGS__)

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_vgm_VgmStub_test(JNIEnv* env, jobject thiz) {
    LOGI("VGM native stub loaded");
    return 1;
}
