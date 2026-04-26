(function () {
    const config = window.AppConfig;
    const TOKEN = config.token;
    const HAS_PASSWORD = config.hasPassword;
    let isAuthenticated = config.isAuthenticated;

    const STORAGE_KEY_ACCESS = 'vaultly_access_token';
    const STORAGE_KEY_MASTER = 'vaultly_master_password';

    function saveCredentials(accessToken, masterPassword) {
        localStorage.setItem(STORAGE_KEY_ACCESS, accessToken);
        if (masterPassword) localStorage.setItem(STORAGE_KEY_MASTER, masterPassword);
    }

    function clearCredentials() {
        localStorage.removeItem(STORAGE_KEY_ACCESS);
        localStorage.removeItem(STORAGE_KEY_MASTER);
    }

    function getStoredAccessToken() {
        return localStorage.getItem(STORAGE_KEY_ACCESS);
    }

    function getStoredMasterPassword() {
        return localStorage.getItem(STORAGE_KEY_MASTER) || '';
    }

    const authSection = document.getElementById('authSection');
    const totpSection = document.getElementById('totpSection');
    const downloadSection = document.getElementById('downloadSection');
    let totpInputs = [];
    let pendingLoginData = null;

    function showError(elementId, message) {
        const el = document.getElementById(elementId);
        if (el) { el.textContent = message; el.style.display = 'block'; }
    }
    function clearError(elementId) {
        const el = document.getElementById(elementId);
        if (el) el.textContent = '';
    }
    function setProgress(message) {
        const el = document.getElementById('progressMessage');
        if (el) el.textContent = message;
    }

    function generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
            const r = Math.random() * 16 | 0;
            return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
        });
    }

    async function authFetch(url, options = {}) {
        const accessToken = getStoredAccessToken();
        if (!accessToken) throw new Error('Нет токена доступа');
        options.headers = { ...options.headers, 'Authorization': `Bearer ${accessToken}` };
        return fetch(url, options);
    }

    function cleanBase64(str) {
        let cleaned = String(str).replace(/\s/g, '').replace(/[^A-Za-z0-9+/=]/g, '');
        cleaned = cleaned.replace(/=+(?=.*=)/g, '');
        while (cleaned.length % 4 !== 0) cleaned += '=';
        return cleaned;
    }

    function arrayBufferToBase64(buffer) {
        let binary = '';
        const bytes = new Uint8Array(buffer);
        for (let i = 0; i < bytes.byteLength; i++) binary += String.fromCharCode(bytes[i]);
        return btoa(binary);
    }

    function base64ToArrayBuffer(base64) {
        const clean = cleanBase64(base64);
        const binary = atob(clean);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
        return bytes.buffer;
    }

    function formatPublicKeyPem(base64Key) {
        const pemHeader = '-----BEGIN PUBLIC KEY-----';
        const pemFooter = '-----END PUBLIC KEY-----';
        const lines = base64Key.match(/.{1,64}/g) || [base64Key];
        return pemHeader + '\n' + lines.join('\n') + '\n' + pemFooter;
    }

    async function generateRSAKeyPair() {
        return crypto.subtle.generateKey(
            { name: "RSA-OAEP", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
            true,
            ["encrypt", "decrypt"]
        );
    }

    async function exportPublicKey(publicKey) {
        const exported = await crypto.subtle.exportKey("spki", publicKey);
        return arrayBufferToBase64(exported);
    }

    async function encryptPrivateKeyToJson(privateKey, password, salt) {
        const pkcs8Der = await crypto.subtle.exportKey("pkcs8", privateKey);
        const pemHeader = '-----BEGIN PRIVATE KEY-----';
        const pemFooter = '-----END PRIVATE KEY-----';
        const base64Body = arrayBufferToBase64(pkcs8Der);
        const lines = base64Body.match(/.{1,64}/g) || [base64Body];
        const pemString = pemHeader + '\n' + lines.join('\n') + '\n' + pemFooter;
        const enc = new TextEncoder();
        const pemBytes = enc.encode(pemString);
        const keyMaterial = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveKey"]);
        const aesKey = await crypto.subtle.deriveKey(
            { name: "PBKDF2", salt, iterations: 100000, hash: "SHA-256" },
            keyMaterial,
            { name: "AES-GCM", length: 256 },
            false,
            ["encrypt"]
        );
        const iv = crypto.getRandomValues(new Uint8Array(12));
        const encrypted = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, aesKey, pemBytes);
        const encryptedBytes = new Uint8Array(encrypted);
        const tagLength = 16;
        const ciphertext = encryptedBytes.slice(0, encryptedBytes.length - tagLength);
        const mac = encryptedBytes.slice(encryptedBytes.length - tagLength);
        return {
            cipherText: arrayBufferToBase64(ciphertext.buffer),
            nonce: arrayBufferToBase64(iv.buffer),
            mac: arrayBufferToBase64(mac.buffer)
        };
    }

    async function decryptPrivateKey(encryptedData, password, saltBase64) {
        let cleaned = encryptedData.trim();
        cleaned = cleaned.replace(/^\uFEFF/, '');
        while ((cleaned.startsWith('"') && cleaned.endsWith('"')) || (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
            cleaned = cleaned.slice(1, -1).trim();
        }
        cleaned = cleaned.replace(/\\"/g, '"');
        cleaned = cleaned.replace(/[\x00-\x1F\x7F]/g, '');
        let json;
        try {
            json = JSON.parse(cleaned);
        } catch (e) {
            throw new Error('Неверный формат зашифрованного ключа');
        }
        if (!json.cipherText || !json.nonce) throw new Error('JSON missing required fields');
        const ciphertext = base64ToArrayBuffer(cleanBase64(String(json.cipherText).trim()));
        const nonce = base64ToArrayBuffer(cleanBase64(String(json.nonce).trim()));
        const salt = base64ToArrayBuffer(cleanBase64(String(saltBase64).trim()));
        const enc = new TextEncoder();
        const keyMaterial = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveKey"]);
        const aesKey = await crypto.subtle.deriveKey(
            { name: "PBKDF2", salt, iterations: 100000, hash: "SHA-256" },
            keyMaterial,
            { name: "AES-GCM", length: 256 },
            false,
            ["decrypt"]
        );
        let combined = ciphertext;
        if (json.mac) {
            const mac = base64ToArrayBuffer(cleanBase64(String(json.mac).trim()));
            const tmp = new Uint8Array(ciphertext.byteLength + mac.byteLength);
            tmp.set(new Uint8Array(ciphertext), 0);
            tmp.set(new Uint8Array(mac), ciphertext.byteLength);
            combined = tmp.buffer;
        }
        let plaintextBuffer;
        try {
            plaintextBuffer = await crypto.subtle.decrypt({ name: "AES-GCM", iv: nonce }, aesKey, combined);
        } catch (e) {
            throw new Error('Не удалось расшифровать приватный ключ. Возможно, неверный мастер-пароль.');
        }
        const plaintextStr = new TextDecoder().decode(plaintextBuffer);
        if (!plaintextStr.includes('BEGIN PRIVATE KEY') && !plaintextStr.includes('BEGIN RSA PRIVATE KEY')) {
            throw new Error('Расшифрованные данные не являются приватным ключом в формате PEM.');
        }
        const pemBody = plaintextStr
            .replace(/-----BEGIN [^-]+-----/, '')
            .replace(/-----END [^-]+-----/, '')
            .replace(/\s/g, '');
        const pkcs8Der = base64ToArrayBuffer(cleanBase64(pemBody));
        try {
            return await crypto.subtle.importKey("pkcs8", pkcs8Der, { name: "RSA-OAEP", hash: "SHA-256" }, false, ["decrypt"]);
        } catch (e) {
            return await crypto.subtle.importKey("pkcs8", pkcs8Der, { name: "RSA-OAEP", hash: "SHA-1" }, false, ["decrypt"]);
        }
    }

    async function decryptShpsFile(buffer, metadata, privateKey) {
        const view = new DataView(buffer);
        const headerLength = view.getInt32(0, false);
        const encryptedAesKey = base64ToArrayBuffer(cleanBase64(metadata.encryptedKey));
        const aesKeyRaw = await crypto.subtle.decrypt({ name: "RSA-OAEP" }, privateKey, encryptedAesKey);
        const aesKey = await crypto.subtle.importKey("raw", aesKeyRaw, "AES-GCM", false, ["decrypt"]);
        const iv = base64ToArrayBuffer(cleanBase64(metadata.iv));
        const encryptedData = buffer.slice(4 + headerLength);
        const decrypted = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, aesKey, encryptedData);
        return new Blob([decrypted], { type: metadata.mimeType });
    }

    async function getOrCreateTempDevice() {
        const devicesResp = await authFetch('/api/device/me-device');
        if (!devicesResp.ok) throw new Error('Ошибка получения устройств');
        const devices = await devicesResp.json();
        let tempDevice = devices.find(d => d.deviceType === 'TEMP_DOWNLOAD');
        if (tempDevice) {
            try {
                const keyResp = await authFetch(`/api/device/${tempDevice.id}/key`);
                if (keyResp.ok) {
                    const key = await keyResp.text();
                    if (key === 'dummy' || key.length < 20) {
                        await authFetch(`/api/device/${tempDevice.id}`, { method: 'DELETE' });
                        tempDevice = null;
                    }
                } else {
                    tempDevice = null;
                }
            } catch (e) {
                tempDevice = null;
            }
        }
        if (tempDevice) return tempDevice.id;
        const profileResp = await authFetch('/api/users/me');
        if (!profileResp.ok) throw new Error('Не удалось получить профиль');
        const profile = await profileResp.json();
        const privateKeyResp = await authFetch('/api/users/me/private-key-encrypted');
        if (!privateKeyResp.ok) throw new Error('Не удалось получить зашифрованный ключ');
        const encryptedPrivateKey = await privateKeyResp.text();
        const createResp = await authFetch('/api/device/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                deviceName: 'Скачивание файлов',
                deviceType: 'TEMP_DOWNLOAD',
                uniqueId: 'temp-' + generateUUID(),
                publicKey: profile.publicKey,
                encryptedPrivateKey
            })
        });
        if (!createResp.ok) {
            const err = await createResp.text();
            throw new Error('Не удалось создать устройство: ' + err);
        }
        const newDevice = await createResp.json();
        return newDevice.id;
    }

    function initDownloadButton() {
        const btn = document.getElementById('decryptDownloadBtn');
        const newBtn = btn.cloneNode(true);
        btn.parentNode.replaceChild(newBtn, btn);
        newBtn.addEventListener('click', async () => {
            const filePassword = document.getElementById('filePassword')?.value || '';
            let masterPassword = document.getElementById('masterPassword').value;
            if (!masterPassword) {
                masterPassword = getStoredMasterPassword();
                if (masterPassword) {
                    document.getElementById('masterPassword').value = masterPassword;
                } else {
                    showError('downloadError', 'Введите мастер-пароль');
                    return;
                }
            }
            clearError('downloadError');
            setProgress('Подготовка...');
            newBtn.disabled = true;
            try {
                setProgress('Получение устройства...');
                const deviceId = await getOrCreateTempDevice();
                setProgress('Получение метаданных...');
                let metaUrl = `/tempacces/version132/temp-access/${TOKEN}/decryption-metadata`;
                if (HAS_PASSWORD && filePassword) metaUrl += `?password=${encodeURIComponent(filePassword)}`;
                const metaResp = await authFetch(metaUrl, { method: 'POST' });
                if (!metaResp.ok) throw new Error(await metaResp.text() || 'Ошибка метаданных');
                const metadata = await metaResp.json();
                setProgress('Получение ключа устройства...');
                const keyResp = await authFetch(`/api/device/${deviceId}/key`);
                if (!keyResp.ok) throw new Error('Не удалось получить ключ устройства');
                const encryptedKey = await keyResp.text();
                setProgress('Получение соли...');
                const saltResp = await authFetch('/api/users/me/salt');
                if (!saltResp.ok) throw new Error('Не удалось получить соль');
                const salt = await saltResp.text();
                setProgress('Расшифровка приватного ключа...');
                const privateKey = await decryptPrivateKey(encryptedKey, masterPassword, salt);
                setProgress('Загрузка файла...');
                const fileResp = await fetch(metadata.presignedUrl);
                if (!fileResp.ok) throw new Error('Ошибка загрузки файла');
                const encryptedBuffer = await fileResp.arrayBuffer();
                setProgress('Расшифровка содержимого...');
                const decryptedBlob = await decryptShpsFile(encryptedBuffer, metadata, privateKey);
                setProgress('Сохранение...');
                const url = URL.createObjectURL(decryptedBlob);
                const a = document.createElement('a');
                a.href = url;
                a.download = metadata.fileName;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
                setProgress('✅ Готово!');
            } catch (err) {
                showError('downloadError', err.message);
                setProgress('');
            } finally {
                newBtn.disabled = false;
            }
        });
    }

    function switchToAuthenticatedUI() {
        authSection.classList.add('hidden');
        totpSection.classList.add('hidden');
        downloadSection.classList.remove('hidden');
        isAuthenticated = true;
        const savedMaster = getStoredMasterPassword();
        if (savedMaster) {
            document.getElementById('masterPassword').value = savedMaster;
        }
        initDownloadButton();
    }

    function createTotpInputs() {
        const container = document.getElementById('totpInputs');
        container.innerHTML = '';
        const inputs = [];
        for (let i = 0; i < 6; i++) {
            const input = document.createElement('input');
            input.type = 'text';
            input.maxLength = 1;
            input.className = 'totp-digit';
            input.inputMode = 'numeric';
            input.pattern = '\\d*';
            input.addEventListener('input', (e) => {
                const val = e.target.value;
                if (val && !/^\d$/.test(val)) {
                    e.target.value = '';
                    return;
                }
                if (val.length === 1 && i < 5) {
                    inputs[i + 1].focus();
                }
                const allFilled = inputs.every(inp => inp.value.length === 1);
                if (allFilled) {
                    const code = inputs.map(inp => inp.value).join('');
                    submitTotp(code);
                }
            });
            input.addEventListener('keydown', (e) => {
                if (e.key === 'Backspace' && !input.value && i > 0) {
                    inputs[i - 1].focus();
                }
            });
            container.appendChild(input);
            inputs.push(input);
        }
        return inputs;
    }

    async function submitTotp(code) {
        if (!pendingLoginData) return;
        clearError('totpError');
        const backBtn = document.getElementById('totpBackBtn');
        backBtn.disabled = true;
        try {
            const resp = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    username: pendingLoginData.username,
                    password: pendingLoginData.password,
                    totpCode: code
                })
            });
            if (!resp.ok) {
                const errData = await resp.json();
                throw new Error(errData.message || 'Неверный код');
            }
            const data = await resp.json();
            saveCredentials(data.accessToken, pendingLoginData.password);
            switchToAuthenticatedUI();
        } catch (err) {
            showError('totpError', err.message);
            totpInputs.forEach(inp => inp.value = '');
            totpInputs[0].focus();
            backBtn.disabled = false;
        }
    }

    function showTotpForm(username, password) {
        pendingLoginData = { username, password };
        authSection.classList.add('hidden');
        totpSection.classList.remove('hidden');
        if (totpInputs.length === 0) {
            totpInputs = createTotpInputs();
        } else {
            totpInputs.forEach(inp => inp.value = '');
        }
        totpInputs[0].focus();
        document.getElementById('totpBackBtn').onclick = () => {
            pendingLoginData = null;
            totpSection.classList.add('hidden');
            authSection.classList.remove('hidden');
        };
    }

    async function handleLogin(username, password) {
        clearError('loginError');
        const btn = document.getElementById('loginBtn');
        btn.disabled = true;
        try {
            const resp = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });
            if (resp.status === 401) {
                const err = await resp.json();
                if (err.error === 'totp_required') {
                    showTotpForm(username, password);
                    btn.disabled = false;
                    return;
                } else {
                    throw new Error(err.message || 'Ошибка входа');
                }
            }
            if (!resp.ok) throw new Error(await resp.text() || 'Ошибка входа');
            const data = await resp.json();
            saveCredentials(data.accessToken, password);
            switchToAuthenticatedUI();
        } catch (err) {
            showError('loginError', err.message);
            btn.disabled = false;
        }
    }

    async function handleRegister(username, password, firstName, lastName) {
        clearError('registerError');
        const btn = document.getElementById('registerBtn');
        btn.disabled = true;
        try {
            const keyPair = await generateRSAKeyPair();
            const publicKeyBase64 = await exportPublicKey(keyPair.publicKey);
            const publicKeyPem = formatPublicKeyPem(publicKeyBase64);
            const salt = crypto.getRandomValues(new Uint8Array(16));
            const saltBase64 = arrayBufferToBase64(salt.buffer);
            const encryptedPrivateJson = await encryptPrivateKeyToJson(keyPair.privateKey, password, salt);
            const privateKeyEncrypted = JSON.stringify(encryptedPrivateJson);
            const resp = await fetch('/api/auth/register', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    username, password, firstName, lastName,
                    publicKey: publicKeyPem,
                    privateKeyEncrypted: privateKeyEncrypted,
                    salt: saltBase64
                })
            });
            if (!resp.ok) throw new Error(await resp.text() || 'Ошибка регистрации');
            const data = await resp.json();
            saveCredentials(data.accessToken, password);
            switchToAuthenticatedUI();
        } catch (err) {
            showError('registerError', err.message);
            btn.disabled = false;
        }
    }

    async function checkAutoLogin() {
        if (isAuthenticated) return;
        const savedToken = getStoredAccessToken();
        if (!savedToken) return;
        try {
            const resp = await fetch('/api/users/me', {
                headers: { 'Authorization': `Bearer ${savedToken}` }
            });
            if (resp.ok) {
                switchToAuthenticatedUI();
            } else {
                clearCredentials();
            }
        } catch (e) {
            clearCredentials();
        }
    }

    function initUI() {
        if (isAuthenticated) {
            authSection.classList.add('hidden');
            totpSection.classList.add('hidden');
            downloadSection.classList.remove('hidden');
            initDownloadButton();
            return;
        }

        authSection.classList.remove('hidden');
        totpSection.classList.add('hidden');
        downloadSection.classList.add('hidden');

        const loginForm = document.getElementById('loginForm');
        const registerForm = document.getElementById('registerForm');
        const loginTab = document.getElementById('loginTabBtn');
        const registerTab = document.getElementById('registerTabBtn');

        loginTab.onclick = () => {
            loginForm.classList.remove('hidden');
            registerForm.classList.add('hidden');
            loginTab.classList.add('active');
            registerTab.classList.remove('active');
        };
        registerTab.onclick = () => {
            registerForm.classList.remove('hidden');
            loginForm.classList.add('hidden');
            registerTab.classList.add('active');
            loginTab.classList.remove('active');
        };

        loginForm.addEventListener('submit', async e => {
            e.preventDefault();
            const username = document.getElementById('loginUsername').value;
            const password = document.getElementById('loginPassword').value;
            await handleLogin(username, password);
        });

        registerForm.addEventListener('submit', async e => {
            e.preventDefault();
            const username = document.getElementById('regUsername').value;
            const password = document.getElementById('regPassword').value;
            const firstName = document.getElementById('regFirstName').value;
            const lastName = document.getElementById('regLastName').value;
            await handleRegister(username, password, firstName, lastName);
        });
    }

    initUI();
    if (!isAuthenticated) {
        checkAutoLogin();
    }
})();