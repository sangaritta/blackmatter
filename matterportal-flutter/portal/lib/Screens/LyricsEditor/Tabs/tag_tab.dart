import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';

class TagTab extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const TagTab({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagTab> createState() => _TagTabState();
}

class _TagTabState extends State<TagTab> {
  final TextEditingController _tagController = TextEditingController();
  final List<String> _suggestedTags = [
    'Verse',
    'Chorus',
    'Bridge',
    'Pre-Chorus',
    'Intro',
    'Outro',
    'Hook',
    'Refrain',
    'Ad-lib',
    'Instrumental',
  ];

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isEmpty) return;
    if (!widget.tags.contains(tag)) {
      final newTags = List<String>.from(widget.tags)..add(tag);
      widget.onTagsChanged(newTags);
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom tag input field
          TextField(
            controller: _tagController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a tag...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1B2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.tag, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () => _addTag(_tagController.text.trim()),
              ),
            ),
            onSubmitted: (value) => _addTag(value.trim()),
          ),
          const SizedBox(height: 16),

          // Suggested tags section
          const Text(
            'Suggested Tags',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: fontNameBold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedTags.map((tag) {
              final isSelected = widget.tags.contains(tag);
              return ActionChip(
                label: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
                backgroundColor:
                    isSelected ? Colors.blue : const Color(0xFF1E1B2C),
                onPressed: () => isSelected ? _removeTag(tag) : _addTag(tag),
                avatar: Icon(
                  isSelected ? Icons.check : Icons.add,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Current tags section
          if (widget.tags.isNotEmpty) ...[
            const Text(
              'Current Tags',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: fontNameBold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blue,
                  deleteIcon:
                      const Icon(Icons.close, size: 16, color: Colors.white),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
