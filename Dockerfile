ARG BUILD_IMAGE=mbtatools/windows-elixir:1.14.0-erlang-25.0.4-windows-1809
ARG FROM_IMAGE=mcr.microsoft.com/windows/servercore:1809

FROM $BUILD_IMAGE as build

ENV MIX_ENV=prod

# log which version of Windows we're using
RUN ver

RUN mkdir C:\trike

WORKDIR C:\\trike

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config/config.exs config\\config.exs
COPY config/prod.exs config\\prod.exs

RUN mix deps.compile

COPY lib lib
COPY config/runtime.exs config\\runtime.exs
RUN mix release

FROM $FROM_IMAGE

USER ContainerAdministrator
RUN curl -fSLo C:\vc_redist.x64.exe https://aka.ms/vs/17/release/vc_redist.x64.exe \
    && .\vc_redist.x64.exe /install /quiet /norestart \
    && del vc_redist.x64.exe

COPY --from=build C:\\trike\\_build\\prod\\rel\\trike C:\\trike

WORKDIR C:\\trike

# Ensure Erlang can run
RUN dir && \
    erts-12.3.2.4\bin\erl -noshell -noinput +V

EXPOSE 8001
CMD ["C:\\trike\\bin\\trike.bat", "start"]
