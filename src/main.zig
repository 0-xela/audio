const std = @import("std");
const Io = std.Io;
const ma = @import("miniaudio.zig");

const audio = @import("audio");

pub fn main(init: std.process.Init) !u8 {
    return try playSine(440.0, 2000, init.io);
}

pub fn dataCallback(
    pDevice: [*c]ma.ma_device,
    pOutput: ?*anyopaque,
    pInput: ?*const anyopaque,
    frameCount: ma.ma_uint32,
) callconv(.c) void {
    const pUserData: *ma.ma_waveform = @ptrCast(@alignCast(pDevice.?.*.pUserData.?));
    const pWaveform: [*]ma.ma_waveform = pUserData[0..1];
    _ = ma.ma_waveform_read_pcm_frames(pWaveform, pOutput, frameCount, null);
    _ = pInput;
}

pub fn playSine(freq: f64, time: i64, io: Io) !u8 {
    // 1. Configure a 440Hz sine wave
    var sineWave: ma.ma_waveform = undefined;
    const sineConfig: ma.ma_waveform_config = ma.ma_waveform_config_init(
        ma.ma_format_f32,
        2,
        48000,
        ma.ma_waveform_type_sawtooth,
        0.2,
        freq,
    );
    _ = ma.ma_waveform_init(&sineConfig, &sineWave);

    // 2. Configure the playback device
    var deviceConfig: ma.ma_device_config = ma.ma_device_config_init(ma.ma_device_type_playback);
    deviceConfig.playback.format = ma.ma_format_f32;
    deviceConfig.playback.channels = 2;
    deviceConfig.sampleRate = 48000;
    deviceConfig.dataCallback = dataCallback;
    deviceConfig.pUserData = &sineWave;

    var device: ma.ma_device = undefined;
    if (ma.ma_device_init(null, &deviceConfig, &device) != ma.MA_SUCCESS) {
        return 255;
    }

    // 3. Play for 2 seconds
    _ = ma.ma_device_start(&device);
    try sleep(io, time);

    // 4. Clean up
    _ = ma.ma_device_uninit(&device);
    _ = ma.ma_waveform_uninit(&sineWave);
    return 0;
}

pub fn sleep(io: Io, millis: i64) !void {
    _ = try io.sleep(std.Io.Duration.fromMilliseconds(millis), .awake);
}
