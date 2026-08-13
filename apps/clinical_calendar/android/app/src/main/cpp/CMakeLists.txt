cmake_minimum_required(VERSION 3.22.1)

project(clinical_calendar_memory LANGUAGES CXX)

add_library(
  clinical_calendar_memory
  SHARED
  native_allocator.cpp
)

target_compile_features(clinical_calendar_memory PRIVATE cxx_std_17)
