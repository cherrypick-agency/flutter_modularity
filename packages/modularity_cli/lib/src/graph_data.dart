import 'recording_binder.dart';

/// Edge types for module relationships.
enum ModuleEdgeType {
  imports,
  owns,
}

/// Represents a node in the module graph.
class ModuleNode {
  ModuleNode({
    required this.id,
    required this.name,
    required this.isRoot,
    required this.publicDependencies,
    required this.privateDependencies,
    required this.warnings,
  });

  final String id;
  final String name;
  final bool isRoot;
  final List<DependencyRecord> publicDependencies;
  final List<DependencyRecord> privateDependencies;
  final List<String> warnings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isRoot': isRoot,
        'publicDependencies': publicDependencies
            .map((DependencyRecord d) =>
                {'type': d.type.toString(), 'kind': d.kind.label})
            .toList(),
        'privateDependencies': privateDependencies
            .map((DependencyRecord d) =>
                {'type': d.type.toString(), 'kind': d.kind.label})
            .toList(),
        'warnings': warnings,
      };
}

/// Represents an edge in the module graph.
class ModuleEdge {
  ModuleEdge({
    required this.source,
    required this.target,
    required this.type,
  });

  final String source;
  final String target;
  final ModuleEdgeType type;

  Map<String, dynamic> toJson() => {
        'source': source,
        'target': target,
        'type': type.name,
      };
}

/// Complete graph data structure for visualization.
class ModuleGraphData {
  ModuleGraphData({
    required this.nodes,
    required this.edges,
  });

  final List<ModuleNode> nodes;
  final List<ModuleEdge> edges;

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}
