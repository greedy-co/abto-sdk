package example;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.springai2.AbtoSpringAI2;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

public final class SpringAI2Example {
    public static void main(String[] args) throws Exception {
        try (var example = ExampleGateway.start(args)) {
            try (var app = new SpringApplicationBuilder(Beans.class).web(WebApplicationType.NONE)
                    .properties("spring.main.banner-mode=off", "logging.level.root=ERROR")
                    .initializers(context -> context.getBeanFactory().registerSingleton("abtoConfig", example.config())).run()) {
                app.getBean(OpenAiChatModel.class).call("Say hello.");
                example.verify("support.spring2");
                System.out.println("Spring AI 2 / Boot 4 example passed.");
            }
        }
    }
    @Configuration(proxyBeanMethods = false)
    static class Beans {
        @Bean AbtoSpringAI2 abto(AbtoConfig config) { return AbtoSpringAI2.create(config); }
        @Bean OpenAiChatModel chatModel(AbtoSpringAI2 abto) {
            var builder = OpenAiChatModel.builder().options(OpenAiChatOptions.builder().model("gpt-4o-mini").build());
            abto.forContext(new AbtoContext("support.spring2")).chatModelOptions().accept(builder);
            return builder.build();
        }
    }
}
