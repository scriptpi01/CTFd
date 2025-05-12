FROM python:3.11-slim-bookworm AS build

WORKDIR /opt/CTFd

# ติดตั้งแพ็กเกจจำเป็นสำหรับการ build
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# คัดลอก source code เข้าไป
COPY . /opt/CTFd

# ติดตั้ง dependencies หลัก + psycopg2-binary
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir psycopg2-binary \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt";\
        fi; \
    done


FROM python:3.11-slim-bookworm AS release

WORKDIR /opt/CTFd

# ติดตั้งไลบรารี runtime ที่จำเป็น
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libffi8 \
        libssl3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# คัดลอก source code ทั้งหมดเข้าไป
COPY --chown=1001:1001 . /opt/CTFd

# สร้าง user และเตรียมโฟลเดอร์ที่จำเป็น
RUN useradd \
    --no-log-init \
    --shell /bin/bash \
    -u 1001 \
    ctfd \
    && mkdir -p /var/log/CTFd /var/uploads \
    && chown -R 1001:1001 /var/log/CTFd /var/uploads /opt/CTFd \
    && chmod +x /opt/CTFd/docker-entrypoint.sh

# คัดลอก virtual environment จาก build stage มาใช้
COPY --chown=1001:1001 --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# สลับเป็น user ปลอดภัย
USER 1001

# เปิดพอร์ตที่ CTFd ใช้
EXPOSE 8000

# กำหนด entrypoint เพื่อให้ CTFd เริ่มทำงาน
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
