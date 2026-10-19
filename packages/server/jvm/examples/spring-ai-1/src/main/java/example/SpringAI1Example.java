package example;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.springai1.AbtoSpringAI1;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

public final class SpringAI1Example {
    public static void main(String[] args) throws Exception {
        try (var example = ExampleGateway.start(args)) {
            try (var app = new SpringApplicationBuilder(Beans.class).web(WebApplicationType.NONE)
                    .properties("spring.main.banner-mode=off", "logging.level.root=ERROR")
                    .initializers(context -> context.getBeanFactory().registerSingleton("abtoConfig", example.config())).run()) {
                app.getBean(OpenAiChatModel.class).call("Say hello.");
                example.verify("support.spring1");
                System.out.println("Spring AI 1 / Boot 3 example passed.");
            }
        }
    }
    @Configuration(proxyBeanMethods = false)
    static class Beans {
        @Bean AbtoSpringAI1 abto(AbtoConfig config) { return AbtoSpringAI1.create(config); }
        @Bean OpenAiChatModel chatModel(AbtoSpringAI1 abto) {
            var builder = OpenAiChatModel.builder().defaultOptions(OpenAiChatOptions.builder().model("gpt-4o-mini").build());
            abto.chatModelOptions(abto.forContext(AbtoContext.of("support.spring1")).openAiApi()).accept(builder);
            return builder.build();
        }
    }
}
