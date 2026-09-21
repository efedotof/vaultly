package com.efedotov.vaultly.controller;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import com.efedotov.vaultly.dto.file.DecryptionMetadata;
import com.efedotov.vaultly.dto.tempaccess.CreateTempLinkRequest;
import com.efedotov.vaultly.dto.tempaccess.FileAccessRequest;
import com.efedotov.vaultly.dto.tempaccess.TempLinkInfo;
import com.efedotov.vaultly.dto.tempaccess.TempLinkResponse;
import com.efedotov.vaultly.model.TempFileAccess;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.DeviceService;
import com.efedotov.vaultly.service.FileService;
import com.efedotov.vaultly.service.TempAccessService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/tempacces/version132")
@RequiredArgsConstructor
public class TempAccessController {

    private final TempAccessService tempAccessService;
    private final DeviceService deviceService;
    private final FileService fileService;

    @PostMapping("/files/{fileId}/public")
    public ResponseEntity<Void> setFilePublic(@PathVariable UUID fileId,
            @RequestBody @Valid FileAccessRequest request) {
        tempAccessService.setFilePublic(fileId, request.getIsPublic());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/temp-access/create")
    public ResponseEntity<TempLinkResponse> createTempLink(@RequestBody @Valid CreateTempLinkRequest request) {
        TempLinkResponse response = tempAccessService.createTempLink(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/temp-access/{token}/metadata")
    public ResponseEntity<Void> checkTempLinkPassword(@PathVariable String token,
            @RequestParam(required = false) String password) {
        tempAccessService.validateTempLink(token, password);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/temp-access/{token}/download")
    public ResponseEntity<StreamingResponseBody> downloadByTempLinkStreaming(
            @PathVariable String token,
            @RequestParam(required = false) String password) {

        TempLinkInfo info = tempAccessService.getTempLinkInfo(token);

        StreamingResponseBody stream = outputStream -> {
            try {
                tempAccessService.streamDecryptedFile(token, password, outputStream);
            } catch (Exception e) {
                log.error("Streaming download failed", e);
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                        "Download failed: " + e.getMessage());
            }
        };

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(info.getMimeType()))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + URLEncoder.encode(info.getFileName(), StandardCharsets.UTF_8)
                                + "\"")
                .body(stream);
    }

    @GetMapping("/{token}")
    public String getTempAccessPage(@PathVariable String token, Model model,
            @AuthenticationPrincipal CustomUserDetails user) {
        TempFileAccess tempAccess = tempAccessService.validateTempLink(token, null);
        model.addAttribute("token", token);
        model.addAttribute("fileName", tempAccess.getFile().getOriginalName());
        model.addAttribute("expiresAt", tempAccess.getExpiresAt());
        model.addAttribute("hasPassword", tempAccess.getPassword() != null && !tempAccess.getPassword().isEmpty());
        model.addAttribute("isAuthenticated", user != null);

        if (user == null) {
            model.addAttribute("redirectAfterLogin", "/tempacces/version132/temp-access/" + token);
        }
        return "temp-download";
    }

    @GetMapping(value = "/temp-access/{token}", produces = MediaType.TEXT_HTML_VALUE)
    public ModelAndView showDownloadPage(@PathVariable String token,
            @AuthenticationPrincipal CustomUserDetails user) {
        TempLinkInfo info = tempAccessService.getTempLinkInfo(token);
        ModelAndView mav = new ModelAndView("temp-download");
        mav.addObject("token", token);
        mav.addObject("fileName", info.getFileName());
        mav.addObject("expiresAt", info.getExpiresAt());
        mav.addObject("hasPassword", info.isHasPassword());

        boolean isAuthenticated = user != null;
        mav.addObject("isAuthenticated", isAuthenticated);

        if (!isAuthenticated) {
            mav.addObject("redirectAfterLogin", "/tempacces/version132/temp-access/" + token);
        } else {
            if (user != null) {
                deviceService.ensureTempDownloadDeviceExists(user.getUserId());
            }
        }
        return mav;
    }

    @PostMapping("/temp-access/{token}/decryption-metadata")
    @ResponseBody
    public DecryptionMetadata getDecryptionMetadata(@PathVariable String token,
            @RequestParam(required = false) String password,
            @AuthenticationPrincipal CustomUserDetails user) {
        TempFileAccess tempAccess = tempAccessService.validateTempLink(token, password);
        tempAccessService.incrementDownloadCount(token);
        return fileService.getDecryptionMetadataForTempAccess(tempAccess.getFile().getId(), user.getUserId());
    }
}