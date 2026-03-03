import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/notes_api_service.dart';
import '../services/deleted_items_service.dart';
import '../utils/responsive_breakpoints.dart';
import 'add_note_screen.dart';
import 'edit_note_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notes = await NotesApiService.getNotes();

      // SORTING LOGIC: Newest at the top
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNote(Note note) async {
    if (note.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Note',
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${note.title}"?',
          style: GoogleFonts.ubuntu(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.ubuntu(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Add to deleted items service before deleting
        DeletedItemsService().addDeletedNote(note);

        await NotesApiService.deleteNote(note.id!);
        if (mounted) _loadNotes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (context) => EditNoteScreen(note: note)),
    );
    if (result != null) _loadNotes();
  }

  Future<void> _addNote() async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(builder: (context) => const AddNoteScreen()),
    );

    if (result != null) {
      try {
        await NotesApiService.createNote(result);
        if (mounted) _loadNotes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating note: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'note_fab_unique',
          onPressed: _addNote,
          tooltip: 'Add Note',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 28),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final theme = Theme.of(context);

        return Column(
          children: [
            Container(
              padding: ResponsiveBreakpoints.getCardPadding(screenWidth),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(bottom: false, child: _buildHeader(screenWidth)),
            ),
            Expanded(child: _buildContent()),
          ],
        );
      },
    );
  }

  Widget _buildHeader(double screenWidth) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

    return Row(
      children: [
        Icon(
          Icons.notes_rounded,
          color: theme.colorScheme.primary,
          size: isMobile ? 24 : 28,
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: Text(
            'Notes',
            style: GoogleFonts.ubuntu(
              fontSize: ResponsiveBreakpoints.getHeaderFontSize(screenWidth),
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (!isMobile) const SizedBox(width: 16),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_notes.length} ${_notes.length == 1 ? 'note' : 'notes'}',
            style: GoogleFonts.ubuntu(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (_isLoading) return const Center(child: CircularProgressIndicator());

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: ResponsiveBreakpoints.isMobile(screenWidth) ? 48 : 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notes',
                  style: GoogleFonts.ubuntu(
                    fontSize: ResponsiveBreakpoints.getTitleFontSize(
                      screenWidth,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadNotes,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (_notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: ResponsiveBreakpoints.isMobile(screenWidth) ? 64 : 96,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notes yet',
                  style: GoogleFonts.ubuntu(
                    color: Colors.grey.shade600,
                    fontSize: ResponsiveBreakpoints.getTitleFontSize(
                      screenWidth,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first note',
                  style: GoogleFonts.ubuntu(
                    color: Colors.grey.shade500,
                    fontSize: ResponsiveBreakpoints.isMobile(screenWidth)
                        ? 14
                        : 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadNotes,
          child: GridView.builder(
            padding: ResponsiveBreakpoints.getScreenPadding(screenWidth)
                .copyWith(
                  top: ResponsiveBreakpoints.getSectionSpacing(screenWidth),
                  bottom: 120, // Space for FAB
                ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getNotesColumns(screenWidth),
              crossAxisSpacing: ResponsiveBreakpoints.getItemSpacing(
                screenWidth,
              ),
              mainAxisSpacing: ResponsiveBreakpoints.getItemSpacing(
                screenWidth,
              ),
              childAspectRatio: _getNotesAspectRatio(screenWidth),
            ),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return NoteCard(
                note: note,
                onDelete: () => _deleteNote(note),
                onEdit: () => _editNote(note),
                baseColor: _getCardColor(index),
                screenWidth: screenWidth,
              );
            },
          ),
        );
      },
    );
  }

  int _getNotesColumns(double screenWidth) {
    if (ResponsiveBreakpoints.isMobile(screenWidth)) return 2;
    if (ResponsiveBreakpoints.isTablet(screenWidth)) return 3;
    return 4;
  }

  double _getNotesAspectRatio(double screenWidth) {
    if (ResponsiveBreakpoints.isMobile(screenWidth)) return 1.1;
    if (ResponsiveBreakpoints.isTablet(screenWidth)) return 1.0;
    return 0.9;
  }

  Color _getCardColor(int index) {
    final colors = [
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Color baseColor;
  final double screenWidth;

  const NoteCard({
    super.key,
    required this.note,
    required this.onDelete,
    required this.onEdit,
    required this.baseColor,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    final cardPadding = ResponsiveBreakpoints.getCardPadding(screenWidth);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withValues(alpha: 0.15),
            baseColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: baseColor.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: baseColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: GoogleFonts.ubuntu(
                          fontSize: isMobile ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Expanded(
                  child: Text(
                    note.content,
                    style: GoogleFonts.ubuntu(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                    maxLines: isMobile ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Note',
                        style: GoogleFonts.ubuntu(
                          fontSize: isMobile ? 9 : 10,
                          fontWeight: FontWeight.w600,
                          color: baseColor.darken(),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Text(
                        _formatDate(note.createdAt),
                        style: GoogleFonts.ubuntu(
                          fontSize: isMobile ? 10 : 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: isMobile ? 16 : 18,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 28 : 32,
                          minHeight: isMobile ? 28 : 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.day}/${date.month}';
  }
}

// Simple extension to help with text visibility on light backgrounds
extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
