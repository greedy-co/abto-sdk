package app.abto.calling.springai2;

import app.abto.calling.AbtoCancellation;
import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.openai.AbtoOpenAI;
import com.openai.client.OpenAIClient;
import java.net.http.HttpClient;
import java.util.function.Consumer;
import org.springframework.ai.openai.OpenAiChatModel;

/** Spring AI 2.0 integration using official clients with shared ABTO request policy. */
public final class AbtoSpringAI2 implements AutoCloseable {
    private final AbtoOpenAI abto;
    private AbtoSpringAI2(AbtoOpenAI abto) { this.abto = abto; }
    public static AbtoSpringAI2 create(AbtoConfig config) { return new AbtoSpringAI2(AbtoOpenAI.create(config)); }
    public static AbtoSpringAI2 create(AbtoConfig config, HttpClient transport) { return new AbtoSpringAI2(AbtoOpenAI.create(config, transport)); }
    public static AbtoSpringAI2 create(AbtoConfig config, OpenAIClient client, HttpClient transport) { return new AbtoSpringAI2(AbtoOpenAI.create(config, client, transport)); }
    public AbtoSpringAI2 forContext(AbtoContext context) { return new AbtoSpringAI2(abto.forContext(context)); }
    public AbtoSpringAI2 withCancellation(AbtoCancellation cancellation) { return new AbtoSpringAI2(abto.withCancellation(cancellation)); }

    /** Apply after customer model/observation options. No global exporter is installed. */
    public Consumer<OpenAiChatModel.Builder> chatModelOptions() {
        return builder -> {
            OpenAIClient client = abto.openai();
            builder.openAiClient(client).openAiClientAsync(client.async());
        };
    }
    public OpenAiChatModel chatModel() {
        var builder = OpenAiChatModel.builder(); chatModelOptions().accept(builder); return builder.build();
    }
    @Override public void close() { abto.close(); }
}
