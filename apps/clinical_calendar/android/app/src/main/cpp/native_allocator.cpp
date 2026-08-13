#include <jni.h>
#include <malloc.h>

extern "C" JNIEXPORT jboolean JNICALL
Java_com_clinicalcalendar_clinical_1calendar_MainActivity_purgeNativeAllocator(
    JNIEnv*,
    jobject) {
  // Flutter's pressure notification releases engine allocations, but Scudo
  // may retain the unused pages in its native high-water mark. Android 16
  // supports the exhaustive purge; M_PURGE also keeps this safe on API 28-33.
  const bool purged = mallopt(M_PURGE, 0) != 0;
  const bool purged_all = mallopt(M_PURGE_ALL, 0) != 0;
  return (purged || purged_all) ? JNI_TRUE : JNI_FALSE;
}
