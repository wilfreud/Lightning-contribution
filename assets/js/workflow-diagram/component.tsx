import React, { MouseEvent } from 'react';
import { createRoot } from 'react-dom/client';
import WorkflowDiagram, { Store } from './src';

type UpdateParams = {
  onNodeClick(event: MouseEvent, node: any): void;
  onJobAddClick(node: any): void;
  onPaneClick(event: MouseEvent): void;
};

export function mount(el: Element | DocumentFragment) {
  const componentRoot = createRoot(el);
  let timeout: string | number | NodeJS.Timeout | undefined;
  // https://usefulangle.com/post/319/javascript-detect-element-resize
  function update({ onNodeClick, onPaneClick, onJobAddClick }: UpdateParams) {
    window.addEventListener('resize', Store.handleResize);

    return componentRoot.render(
      <WorkflowDiagram
        className="h-8"
        onJobAddClick={onJobAddClick}
        onNodeClick={onNodeClick}
        onPaneClick={onPaneClick}
      />
    );
  }

  function unmount() {
    window.removeEventListener('resize', Store.handleResize);
    return componentRoot.unmount();
  }

  componentRoot.render(<h1>Loading</h1>);

  return { update, unmount, setProjectSpace: Store.setProjectSpace };
}
