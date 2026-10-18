import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/strings.dart';
import '../../models/models.dart';
import '../../widgets/ui.dart';

/// Preview-before-publish screen shared by all composers.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({
    super.key,
    required this.post,
    required this.onPublish,
    this.publishLabel = S.publish,
    this.extra,
  });

  final Post post;
  final Future<void> Function() onPublish;
  final String publishLabel;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.preview)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                          name: post.authorName,
                          avatarPath: post.authorAvatar,
                          radius: 18),
                      const SizedBox(width: 10),
                      Text(post.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(C.postTypeLabel(post.type),
                          style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (post.title.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(post.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                fontWeight: FontWeight.w700)),
                  ],
                  if (post.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(post.body),
                  ],
                  if (extra != null) ...[
                    const SizedBox(height: 8),
                    extra!,
                  ],
                  for (final pth in post.imagePaths) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(pth),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 1200,
                      ),
                    ),
                  ],
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TagChips(tags: post.tags),
                  ],
                  if (post.subject.isNotEmpty ||
                      post.level.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      [post.subject, post.level]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: () async => onPublish(),
              child: Text(publishLabel),
            ),
          ),
        ],
      ),
    );
  }
}
