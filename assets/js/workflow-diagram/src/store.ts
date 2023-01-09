import {
  applyEdgeChanges,
  applyNodeChanges,
  Edge,
  EdgeChange,
  Node,
  NodeChange,
  OnEdgesChange,
  OnNodesChange,
  OnSelectionChangeFunc,
  ReactFlowInstance,
} from 'react-flow-renderer';
import { ProjectSpace, Workflow } from './types';
import create from 'zustand';
import { doLayout, toElkNode, toFlow } from './layout';
import { FlowElkNode } from './layout/types';
import { workflowNodeFactory } from './layout/factories';

type RFState = {
  nodes: Node[];
  edges: Edge[];
  elkNode: FlowElkNode | null;
  projectSpace: ProjectSpace | null;
  onNodesChange: OnNodesChange;
  onEdgesChange: OnEdgesChange;
  onSelectedNodeChange: OnSelectionChangeFunc;
  reactFlowInstance: ReactFlowInstance | null;
  selectedNode: Node | undefined;
};

export const useStore = create<RFState>((set, get) => ({
  projectSpace: null,
  elkNode: null,
  nodes: [],
  edges: [],
  onNodesChange: (changes: NodeChange[]) => {
    set({
      nodes: applyNodeChanges(changes, get().nodes),
    });
  },
  onEdgesChange: (changes: EdgeChange[]) => {
    set({
      edges: applyEdgeChanges(changes, get().edges),
    });
  },
  onSelectedNodeChange: ({ nodes }: { nodes: Node[] }) => {
    set({ selectedNode: nodes[0] });
  },
  reactFlowInstance: null,
  selectedNode: undefined,
}));

// // focus on a given node
// rf.fitBounds({ x: 40, y: 180, width: 150, height: 40 }, { duration: 1000 });
// // revert back (can get the values from rf.getViewport())
// rf.setViewport({ x: 302, y: 209.5, zoom: 2 }, { duration: 1000 });

export async function setProjectSpace(
  projectSpace: ProjectSpace
): Promise<void> {
  let elkNode: FlowElkNode = toElkNode(projectSpace);

  elkNode = await doLayout(elkNode);

  const [nodes, edges] = toFlow(elkNode);

  useStore.setState({ nodes, edges, projectSpace, elkNode });
}

export async function addWorkspace(workflow: Workflow) {
  let elkNode = useStore.getState().elkNode;

  if (elkNode) {
    (elkNode.children || []).push(workflowNodeFactory(workflow));
  } else {
    throw new Error("ElkNode layout not present, can't addWorkspace.");
  }

  elkNode = await doLayout(elkNode);

  const [nodes, edges] = toFlow(elkNode);

  useStore.setState({ nodes, edges, elkNode });
}

export function setReactFlowInstance(rf: ReactFlowInstance) {
  useStore.setState({ reactFlowInstance: rf });
}

let timeout: string | number | NodeJS.Timeout | undefined;

export function handleResize() {
  clearTimeout(timeout);
  timeout = setTimeout(() => console.log('browser resized'), 250);
}
