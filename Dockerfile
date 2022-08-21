FROM sphinxdoc/sphinx

WORKDIR /github/workspace/docs
COPY requirements.txt /github/workspace/docs/requirements.txt
RUN pip3 install -r requirements.txt

RUN apt-get update \
    && apt-get install -y \
          git \
    && apt-get install -y \
          curl \          
    && apt-get autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
