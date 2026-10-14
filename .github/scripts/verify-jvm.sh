#!/usr/bin/env bash
# Build and consume only the exported JVM SDK. All temporary consumer caches are removed.
set -euo pipefail
sdk_root="$(cd "${1:-packages/server/jvm}" && pwd)"
java_version="${JVM_JAVA_VERSION:-17}"
openai_version="${OPENAI_JAVA_VERSION:-4.49.0}"
scratch="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/abto-jvm-verify-XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
maven_version=3.9.11
maven_sha512=bcfe4fe305c962ace56ac7b5fc7a08b87d5abd8b7e89027ab251069faebee516b0ded8961445d6d91ec1985dfe30f8153268843c89aa392733d1a3ec956c9978
curl --fail --silent --show-error --location \
  "https://archive.apache.org/dist/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz" \
  --output "$scratch/maven.tar.gz"
printf '%s  %s\n' "$maven_sha512" "$scratch/maven.tar.gz" | shasum -a 512 --check
tar -xzf "$scratch/maven.tar.gz" -C "$scratch"
gradle -p "$sdk_root" build \
  --no-daemon --no-configuration-cache "-PjavaVersion=$java_version" "-PopenaiVersion=$openai_version"
# Publish the canonical dependency baseline, then consume that same JAR with each runtime version.
gradle -p "$sdk_root" publishAllPublicationsToCentralBundleRepository \
  --no-daemon --no-configuration-cache "-PjavaVersion=$java_version" -PopenaiVersion=4.49.0
"$scratch/apache-maven-${maven_version}/bin/mvn" -B -ntp -f "$sdk_root/examples/pom.xml" clean verify \
  "-Dmaven.repo.local=$scratch/maven-repository" \
  "-Dabto.repository=file:$sdk_root/build/central-staging" "-Dopenai.version=$openai_version" \
  "-DspringBoot1Version=${SPRING_BOOT_1_VERSION:-3.5.16}" \
  "-DspringBoot2Version=${SPRING_BOOT_2_VERSION:-4.1.1}"
gradle -p "$sdk_root/examples/gradle" clean run --no-daemon --no-configuration-cache \
  --refresh-dependencies -Pkotlin.compiler.execution.strategy=in-process \
  "-PjavaVersion=$java_version" "-PabtoRepository=file:$sdk_root/build/central-staging" "-PopenaiVersion=$openai_version" \
  "-PspringBoot1Version=${SPRING_BOOT_1_VERSION:-3.5.16}" \
  "-PspringBoot2Version=${SPRING_BOOT_2_VERSION:-4.1.1}"
