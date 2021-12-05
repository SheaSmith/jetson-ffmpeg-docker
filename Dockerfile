FROM nvcr.io/nvidia/l4t-base:r32.6.1 AS build
COPY . /build
RUN apt-get update && apt-get -y --autoremove install build-essential git libass-dev cmake
RUN cp /build/jetson-ffmpeg/ffmpeg_nvmpi.patch /build/ffmpeg && cd /build/ffmpeg && git apply ffmpeg_nvmpi.patch && mv /build/jetson_multimedia_api /usr/src
WORKDIR /build/jetson-ffmpeg
RUN mkdir build && cd build && cmake .. && make -j4 && make install && ldconfig
WORKDIR /build/ffmpeg
RUN ./configure --enable-nvmpi --enable-libass && make -j4

FROM nvcr.io/nvidia/l4t-base:r32.6.1
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
COPY --from=build /usr/local/lib/libnvmpi.a /usr/local/lib
COPY --from=build /usr/local/lib/libnvmpi.so.1.0.0 /usr/local/lib
COPY --from=build /build/ffmpeg/ffmpeg /usr/local/bin
COPY --from=build /build/ffmpeg/ffprobe /usr/local/bin
RUN ln /usr/local/lib/libnvmpi.so.1.0.0 /usr/local/lib/libnvmpi.so

ENV         LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:/usr/lib:/usr/lib64:/lib:/lib64

CMD         ["--help"]
ENTRYPOINT  ["ffmpeg"]

COPY --from=build /usr/local /usr/local/
