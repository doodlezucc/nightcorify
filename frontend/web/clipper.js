class ClippingProcessor extends AudioWorkletProcessor {
    process(inputs, outputs, parameters) {
        const input = inputs[0];
        const output = outputs[0];
        input.forEach((channel, chIndex) => {
            for (let i = 0; i < channel.length; i++) {
                var v = channel[i];
                if (v > -1 && v < 1) {
                    output[chIndex][i] = channel[i];
                } else {
                    output[chIndex][i] = Math.sign(channel[i]);
                }
            }
        });
        return true;
    }
}

registerProcessor('clipper', ClippingProcessor);